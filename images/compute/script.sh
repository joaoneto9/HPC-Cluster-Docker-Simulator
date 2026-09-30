#!/bin/bash

setup_munge() {
    cp /tmp/munge.key /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key
    chown -R munge:munge /etc/munge /run/munge
    chmod 400 /etc/munge/munge.key
}

setup_slurm() {
    chown slurm:slurm /var/spool/slurmctld && \
    chown slurm:slurm /etc/slurm
}

setup_munge
setup_slurm

su -s /bin/bash munge -c "munged --foreground" & 
prometheus-node-exporter &
slurmd -D
 

