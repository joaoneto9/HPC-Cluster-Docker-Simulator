#!/bin/bash

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