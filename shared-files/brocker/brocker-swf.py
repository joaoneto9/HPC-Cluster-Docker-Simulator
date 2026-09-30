#!/usr/bin/env python3
"""
Replay de um trace .swf no cluster Slurm REAL (sem simular/emular).

Cada job do trace vira um `sbatch` de um toy-job (sleep via srun), com:
  - instante de submissao  = submit_time do SWF * time_scale
  - duracao real do job    = run_time do SWF * time_scale
  - numero de tarefas      = procs do SWF reescalados para o tamanho do cluster
  - limite de tempo        = requested_time do SWF * time_scale (em minutos)

Uso (dentro do container de login):
  python3 swf_replay.py trace.swf --time-scale 0.001 --limit 200
  python3 swf_replay.py trace.swf --dry-run
"""
import argparse
import math
import subprocess
import time


def parse_swf(path):
    """Campos SWF (0-based): 0 id, 1 submit, 3 run, 4 alloc procs,
    7 req procs, 8 req time, 11 user. Linhas com ';' sao comentarios."""
    jobs = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            c = line.split()
            if len(c) < 18:
                continue
            procs = int(float(c[4]))
            if procs <= 0:
                procs = int(float(c[7]))
            runtime = float(c[3])
            if procs <= 0 or runtime <= 0:
                continue  # job sem informacao util (-1)
            jobs.append({
                "id": int(c[0]),
                "submit": float(c[1]),
                "runtime": runtime,
                "procs": procs,
                "req_time": float(c[8]),
                "user": c[11],
            })
    jobs.sort(key=lambda j: j["submit"])
    return jobs


def cluster_cpus():
    # %C => alocadas/ociosas/outras/total
    out = subprocess.check_output(["sinfo", "-h", "-o", "%C"], text=True)
    return int(out.strip().split("/")[3])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("swf")
    ap.add_argument("--time-scale", type=float, default=0.001,
                    help="fator aplicado a submit/runtime (0.001 = 1000x mais rapido)")
    ap.add_argument("--max-cpus", type=int, default=None,
                    help="CPUs do cluster (default: detecta via sinfo)")
    ap.add_argument("--limit", type=int, default=None, help="so os N primeiros jobs")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    jobs = parse_swf(args.swf)
    if args.limit:
        jobs = jobs[: args.limit]
    if not jobs:
        raise SystemExit("nenhum job valido no trace")

    max_cpus = args.max_cpus or (1 if args.dry_run else cluster_cpus())
    trace_max = max(j["procs"] for j in jobs)
    t0 = jobs[0]["submit"]
    start = time.time()

    for j in jobs:
        # reescala proporcional: o maior job do trace ocupa o cluster inteiro
        ntasks = max(1, round(j["procs"] / trace_max * max_cpus))
        dur = max(1, round(j["runtime"] * args.time_scale))
        req = j["req_time"] if j["req_time"] > 0 else j["runtime"] * 2
        # Slurm trabalha com limite em minutos (minimo 1)
        limit_min = max(1, math.ceil(req * args.time_scale / 60), math.ceil((dur + 5) / 60))

        # espera ate o instante de submissao (escalado)
        target = (j["submit"] - t0) * args.time_scale
        delay = target - (time.time() - start)
        if delay > 0 and not args.dry_run:
            time.sleep(delay)

        cmd = [
            "sbatch",
            f"--job-name=swf{j['id']}",
            f"--ntasks={ntasks}",
            f"--time={limit_min}",
            f"--comment=swf-user{j['user']}",
            "--output=/dev/null",
            f"--wrap=srun sleep {dur}",  # troque por stress-ng/apptainer se quiser carga real
        ]
        if args.dry_run:
            print(f"t+{target:8.1f}s ", " ".join(cmd))
        else:
            subprocess.run(cmd, check=False)


if __name__ == "__main__":
    main()