# HPC-Cluster-Docker-Simulator
Docker-based HPC cluster simulator with four containers representing a login node, controller node, and two compute nodes, managed by Slurm for job scheduling and parallel execution.


## Starting

- Clone the repository
- Put the correct content of the files: 

1. **munge.key.example** -> **munge.key** (generate the correct key archive value in the section "Geting a valid munge.key")
2. **slurm.conf.example** -> **slurm.conf**
3. **cgroup.conf.example** -> **cgroup.conf**

```bash
cp ./credentials/slurm/slurm.conf.example ./credentials/slurm/slurm.conf
cp ./credentials/slurm/cgroup.conf.example ./credentials/slurm/cgroup.conf
```

- For the last two archives you can just change the names.
- But for the first one - **munge.key** - you may need to do some steps to generate a valid munge key fie.

## Geting a valid munge.key file

```bash
dd if=/dev/urandom bs=1 count=1024 of=./credentials/munge/munge.key
```

- With this command the private key archive value will be generate at the path **./credentials/munge/munge.key**.
- This path will be shared with the containers by the docker volumes to the **/etc/munge/munge.key** path in the containers.

## How to config the permissions

- There are some archives or directories that the **munge** and the **slurm** have to be the owners.
- For that we need to understand that the **munge** user in the containers is UID=100 and GID=101, also the **slurm** user in the container  is UID=999 and GID=999.
- Althougth, the entrypoint file do this:

```sh
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
```

## How to Submit Jobs

- For now, jobs are submitted using **Slurm's `srun` command** together with **Apptainer**. 
- This approach allows each job to be executed inside an isolated container image containing the dependencies required by the application, without requiring those dependencies to be installed directly on the compute nodes.
- Before submitting a job, the required execution environment must be defined in an Apptainer definition file (`.def`). This file specifies the base image, software packages, libraries, environment variables, and other configurations required by the application.


### Install the apptainer dependencie in your machine (host):

```bash
sudo apt install -y apptainer
```

### Create the image for the job in the Host: 

- The `.def` file is then used to build an Apptainer image in the **SIF (`.sif`) format**:

```bash
apptainer build ./shared-files/jobs/job-1/mpi-python.sif ./shared-files/jobs/job-1/mpi-python.def
```

### Build the container and connect to the Login node:

- After the configurations run this command to build the cluster:

```bash
docker compose up -d
``` 

- Run this command to get into the **login** container:

```bash
docker exec -it [nome-do-container-de-login] /bin/bash
```

### Submitting the job with `srun`:

- Once the image has been created, it can be used when submitting the job through Slurm. For example:

```bash
srun \
  --nodes=2 \
  --ntasks=2 \
  --ntasks-per-node=1 \
  --time=00:05:00 \
  --mpi=pmix \
  apptainer exec --no-mount /etc/localtime mpi-python.sif \
  python3 program.py
```

- **observation-1:** In this workflow, `srun` is responsible for requesting and launching the required tasks across the Slurm-managed compute nodes, while Apptainer provides the isolated software environment in which the application is executed.

- **observation-2:** This separation allows the compute nodes to remain independent of application-specific dependencies. Instead, the dependencies required by a particular job are packaged within its corresponding Apptainer image.
