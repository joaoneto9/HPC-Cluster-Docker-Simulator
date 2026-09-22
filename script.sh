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

case "$NODE_ROLE" in
    controller) 
        su -s /bin/bash munge -c "munged --foreground" & 
        slurmctld -D
        ;; 
    compute)  
        su -s /bin/bash munge -c "munged --foreground" & 
        slurmd -D
        ;;
    login)
        su -s /bin/bash munge -c "munged --foreground" 
        ;;
    *)
        echo "ENVIOROMENT ERROR"
        exit 1
        ;;
esac