FROM ubuntu:latest

WORKDIR /app

RUN apt-get update && \
    apt-get install -y \
        curl \
        munge \
        slurm-client \
        python3 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/munge /run/munge

RUN mkdir -p /etc/slurm 

COPY script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT [ "/script.sh" ]