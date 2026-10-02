#!/bin/bash

setup_munge() {
    cp /tmp/munge.key /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key
    chown -R munge:munge /etc/munge /run/munge
    chmod 400 /etc/munge/munge.key
}

setup_munge

su -s /bin/bash munge -c "munged --foreground" 
