FROM ubuntu:latest

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
        munge \
        slurmd \
        slurmctld \
        slurm-client \
        apptainer \
        squashfuse \
        fuse3 \
        fuse-overlayfs \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/munge /etc/munge && \
    chown munge:munge /run/munge /etc/munge

RUN mkdir -p /var/spool/slurmctld /var/log/slurm && \
    chown slurm:slurm /var/spool/slurmctld

RUN mkdir -p /var/spool/slurmd

COPY script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT [ "/script.sh" ]