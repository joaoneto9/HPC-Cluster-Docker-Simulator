.PHONY: setup key force-key install-apptainer image up wait login down status run help

setup: ## Prepara configs e chave
	mkdir -p ./credentials/slurm ./credentials/munge
	cp -n ./credentials/slurm/slurm.conf.example ./credentials/slurm/slurm.conf
	cp -n ./credentials/slurm/cgroup.conf.example ./credentials/slurm/cgroup.conf
	@$(MAKE) --no-print-directory key

key: ## Gera munge.key se ausente
	@if [ ! -f ./credentials/munge/munge.key ]; then \
		dd if=/dev/urandom bs=1 count=1024 of=./credentials/munge/munge.key; \
	fi

force-key: ## Regenera munge.key
	dd if=/dev/urandom bs=1 count=1024 of=./credentials/munge/munge.key

install-apptainer: ## Instala apptainer no host
	sudo apt install -y apptainer

image: ## Constrói a SIF se não existir
	@[ -f ./shared-files/jobs/job-1/mpi-python.sif ] || \
		apptainer build ./shared-files/jobs/job-1/mpi-python.sif ./shared-files/jobs/job-1/mpi-python.def

up: ## Sobe o cluster
	docker compose up -d --build

wait: ## Aguarda cluster pronto
	@set -e; n=0; \
	while [ $$n -lt 60 ]; do \
		up=$$(docker compose ps --format '{{.State}}' | grep -c 'running'); \
		if [ "$$up" -ge 4 ] && docker compose exec -T login pgrep munged >/dev/null 2>&1; then \
			break; \
		fi; \
		sleep 2; n=$$((n+1)); \
	done; \
	[ $$n -lt 60 ] || { echo "Cluster não ficou pronto em 120s"; exit 1; }

login: ## Entra no nó de login
	docker compose exec login bash

down: ## Derruba o cluster
	docker compose down

status: ## Status dos containers
	docker compose ps

run: ## Prepara, sobe e loga no login
	@command -v apptainer >/dev/null || { echo "apptainer ausente: rode 'make install-apptainer'"; exit 1; }
	@$(MAKE) --no-print-directory setup image up wait login

help: ## Lista targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'