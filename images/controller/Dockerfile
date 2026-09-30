FROM ubuntu:latest

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
        curl \
        munge \
        slurmctld \
        prometheus \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/munge /run/munge

RUN mkdir -p /etc/slurm /var/spool/slurmctld /var/log/slurm

COPY script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT [ "/script.sh" ]