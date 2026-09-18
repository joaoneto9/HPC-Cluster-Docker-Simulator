# HPC-Cluster-Docker-Simulator
Docker-based HPC cluster simulator with four containers representing a login node, controller node, and two compute nodes, managed by Slurm for job scheduling and parallel execution.


## Starting

- Clone the repository
- Put the correct content of the files: 

1. **munge.key.example** -> **munge.key**
2. **slurm.conf.example** -> **slurm.conf**
3. **cgroup.conf.example** -> **cgroup.conf**

- For the last two archives you can just change the names.
- But for the first one - **munge.key** - you may need to do some steps to generate a valid munge key fie.

## Geting a valid munge.key file

## How to config the permissions

- There are some archives or directories that the **munge** and the **slurm** have to be the owners.
- For that we need to understand that the **munge** user in the containers is UID=100 and GID=101, also the **slurm** user in the container  is UID=999 and GID=999.
- So after cloning the repository you may need to set this information running this commands:

```bash
sudo chown 999:999 ./credentials/slurm
sudo chown 100:101 ./credentials/munge
sudo chown 100:101 ./credentials/munge/munge.key
```

## How to build the cluster

- After the configurations run this command to build the cluster:

```bash
docker compose up -d
```

- Run this command to get into the **login** container:

```bash
docker exec -it hpc-cluster-simulation-login-1 /bin/bash
```

## How to submit jobs