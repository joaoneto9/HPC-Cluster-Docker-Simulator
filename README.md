# HPC-Cluster-Docker-Simulator
Docker-based HPC cluster simulator with four containers representing a login node, controller node, and two compute nodes, managed by Slurm for job scheduling and parallel execution.


## Starting

- If you want to run with the make commands go to the section **Using Makefile**.
- But if you want to undarstand each step to run the cluster stay in this section.

### Cloning and setting up files

- Clone the repository
- Put the correct content of the files: 

```bash
cp ./credentials/slurm/slurm.conf.example ./credentials/slurm/slurm.conf
cp ./credentials/slurm/cgroup.conf.example ./credentials/slurm/cgroup.conf
```

### Geting a valid munge.key file

```bash
dd if=/dev/urandom bs=1 count=1024 of=./credentials/munge/munge.key
```

- With this command the private key archive value will be generate at the path **./credentials/munge/munge.key**.
- This path will be shared with the containers by the docker volumes to the **/etc/munge/munge.key** path in the containers.

### How to config the permissions

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

### How to Submit Jobs

- For now, jobs are submitted using **Slurm's `srun` command** together with **Apptainer**. 
- This approach allows each job to be executed inside an isolated container image containing the dependencies required by the application, without requiring those dependencies to be installed directly on the compute nodes.
- Before submitting a job, the required execution environment must be defined in an Apptainer definition file (`.def`). This file specifies the base image, software packages, libraries, environment variables, and other configurations required by the application.


#### Install the apptainer dependencie in your machine (host):

```bash
sudo apt install -y apptainer
```

#### Create the image for the job in the Host: 

- The `.def` file is then used to build an Apptainer image in the **SIF (`.sif`) format**:

```bash
apptainer build ./shared-files/jobs/job-1/mpi-python.sif ./shared-files/jobs/job-1/mpi-python.def
```

#### Build the container and connect to the Login node:

- After the configurations run this command to build the cluster:

```bash
docker compose up -d
``` 

- Run this command to get into the **login** container:

```bash
docker exec -it [nome-do-container-de-login] /bin/bash
```

#### Submitting the job with `srun`:

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

## Using the Makefile

A `Makefile` abstracts all the commands described above into simple, idempotent targets, allowing you to set up and orchestrate the whole cluster with a single tool.

### Available targets

| Target | Description |
|--------|-------------|
| `make setup` | Copies `slurm.conf` and `cgroup.conf` from the `.example` templates and generates `munge.key` (only if it does not already exist). |
| `make key` | Generates `munge.key` only if it is missing. |
| `make force-key` | Regenerates the munge key (beware: this invalidates the authentication of a running cluster). |
| `make install-apptainer` | Installs the `apptainer` dependency on the host (`sudo apt install -y apptainer`). |
| `make image` | Builds the Apptainer SIF image for `job-1`. |
| `make up` | Builds the Docker image and brings up the cluster (`docker compose up -d --build`). |
| `make wait` | Waits until the cluster is ready: all 4 containers `running` and `munged` alive on the **login** node (times out after 120s). |
| `make login` | Opens a shell in the **login** node (`docker compose exec login bash`). |
| `make run` | Does everything in one shot: `setup` → `image` → `up` → `wait` → `login`, dropping you directly into the **login** node shell. |
| `make down` | Tears down the cluster (`docker compose down`). |
| `make status` | Shows the status of the containers (`docker compose ps`). |
| `make help` | Lists all available targets. |

### Recommended workflow

Once the repository is cloned, run:

```bash
make install-apptainer # (optional) install apptainer on the host if not present
make run              # setup + image + up + wait, then enter the login node
```

This is equivalent to running the individual targets step by step:

```bash
make setup            # prepare configs and munge key
make image            # build the job-1 SIF image
make up               # build and start the cluster
make wait             # wait until all nodes are ready
make login            # enter the login node
```

From inside the login node you can then submit your job with `srun`:

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

When you are done:

```bash
make down             # stop and remove the containers
```

### Notes

- `make setup` is idempotent: it never overwrites existing configs or an existing `munge.key`, so a running cluster is not broken by re-running it.
- `make up` includes `--build`, so the Docker image is rebuilt whenever the `Dockerfile` changes.
- `make run` is non-interactive until the `login` step: `wait` checks `docker compose ps` for containers in the `running` state (not `Up`) before dropping you into the login node, so no manual `docker exec` is needed.
- Use `make force-key` only when you intentionally want to regenerate the munge key (e.g. for a fresh cluster); the current cluster will lose access.
