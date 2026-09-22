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

RUN mkdir -p /etc/munge /run/munge

RUN mkdir -p /etc/slurm /var/spool/slurmctld /var/log/slurm /var/spool/slurmd

COPY script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT [ "/script.sh" ]