from mpi4py import MPI
import socket

comm = MPI.COMM_WORLD

rank = comm.Get_rank()
size = comm.Get_size()

hostname = socket.gethostname()

if size != 2:
    if rank == 0:
        print("Este programa precisa ser executado com exatamente 2 ranks.")
    MPI.Finalize()
    exit()

# Rank 0 envia uma mensagem para o Rank 1
if rank == 0:

    mensagem = "Olá, Rank 1! Aqui é o Rank 0."

    print(
        f"[Rank {rank} | {hostname}] Enviando: '{mensagem}'",
        flush=True
    )

    comm.send(mensagem, dest=1, tag=100)

    # Aguarda a resposta do Rank 1
    resposta = comm.recv(source=1, tag=200)

    print(
        f"[Rank {rank} | {hostname}] Recebi: '{resposta}'",
        flush=True
    )


# Rank 1 recebe a mensagem do Rank 0
elif rank == 1:

    mensagem = comm.recv(source=0, tag=100)

    print(
        f"[Rank {rank} | {hostname}] Recebi: '{mensagem}'",
        flush=True
    )

    resposta = "Olá, Rank 0! Mensagem recebida com sucesso."

    print(
        f"[Rank {rank} | {hostname}] Enviando: '{resposta}'",
        flush=True
    )

    comm.send(resposta, dest=0, tag=200)