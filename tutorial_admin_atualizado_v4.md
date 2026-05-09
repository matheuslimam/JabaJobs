# Tutorial do Administrador do Cluster

Este documento é voltado para quem administra o cluster da faculdade.
O objetivo é manter o ambiente organizado, seguro e fácil de usar para usuários que treinam modelos de IA.

---

## 1. Arquitetura adotada

O cluster foi organizado assim:

- **MSI** = `cluster-login`
  - nó de login
  - acesso remoto principal por **Tailscale + SSH**
  - uso com **VS Code Remote-SSH**
  - armazenamento de `/home`
  - controlador do Slurm (`slurmctld`)
  - também pode executar jobs menores na fila `gtx1660`

- **Dell** = `gpu-a4000`
  - nó de treino principal
  - `slurmd`
  - fila `a4000`

### Ideia central

Os usuários:

- entram apenas no `cluster-login`
- editam código e organizam arquivos lá
- submetem treinos pela fila
- não devem treinar diretamente no terminal do login node
- acessam o cluster de fora da faculdade preferencialmente por **Tailscale**

---

## 2. Política de acesso remoto

### Método oficial recomendado

O acesso remoto oficial deve ser feito por:

- **Tailscale** no notebook do usuário
- **Tailscale** no `cluster-login`
- **SSH** sobre o IP ou nome do Tailscale
- **VS Code Remote-SSH** usando esse mesmo endereço

### Motivo

Durante os testes do ambiente, o host respondeu a ICMP, mas conexões TCP externas para `22`, `2222` e `443` não chegaram à interface do servidor. Na prática, isso indica filtragem de TCP de entrada antes do Linux do `cluster-login`.

Por isso:

- **SSH público direto não deve ser tratado como método principal de acesso**
- o caminho suportado para acesso remoto passa a ser **Tailscale**

---

## 3. Responsabilidades do administrador

O administrador deve cuidar de:

- criação de usuários
- redefinição de senha
- verificação de espaço em disco
- verificação do Slurm
- verificação de GPU
- suporte básico a Conda e ambientes
- manutenção do SSH
- manutenção do NFS
- manutenção do MUNGE
- manutenção do Tailscale
- monitoramento de jobs travados
- organização geral do uso

---

## 4. Regras operacionais

### Regra 1
Usuários entram apenas no `cluster-login`.

### Regra 2
Treinos devem ser feitos apenas por:

```bash
run-a4000 ...
run-1660 ...
shell-a4000
```

### Regra 3
Usuários não devem instalar pacotes globais com `sudo`.

### Regra 4
Cada usuário é responsável pelo próprio ambiente Conda.

### Regra 5
O administrador deve evitar mexer manualmente em arquivos do usuário, exceto em manutenção autorizada.

### Regra 6
Acesso remoto externo deve ser orientado via **Tailscale**, não via SSH público direto.

---

## 5. Comandos principais de administração

### Ver status do Slurm

```bash
scontrol ping
sinfo
squeue
scontrol show nodes
```

### Ver jobs de um usuário

```bash
squeue -u nome_do_usuario
```

### Cancelar job

```bash
scancel JOBID
```

### Ver logs do systemd

```bash
journalctl -u slurmctld -n 100 --no-pager
journalctl -u slurmd -n 100 --no-pager
journalctl -u munge -n 100 --no-pager
journalctl -u ssh -n 100 --no-pager
```

---

## 6. Criação de usuários

A ideia é criar o usuário uma única vez e replicar o UID/GID corretamente no nó remoto.

### Script recomendado

O script usado é:

```bash
/usr/local/sbin/novo_usuario.sh
```

### Uso

```bash
sudo novo_usuario.sh alice lince2
sudo passwd alice
```

### O que o script faz

- cria o usuário no `cluster-login`
- cria a home em `/home`
- adiciona o usuário ao grupo `clusterusers`
- cria:
  - `~/projects`
  - `~/datasets`
  - `~/logs`
- replica o mesmo UID/GID na `gpu-a4000`
- não cria home local na Dell, pois o `/home` vem por NFS
- usa `scp` + `sudo bash` na Dell para evitar problemas com `sudo` lendo senha e script na mesma entrada padrão

### Pré-requisitos para o script funcionar

- o usuário remoto de administração da Dell deve existir
- esse usuário deve conseguir fazer SSH na Dell
- esse usuário deve estar no grupo `sudo` da Dell

### Conferência após criar usuário

```bash
id alice
ls -la /home/alice
ssh lince2@gpu-a4000 "id alice; getent passwd alice"
```

---

## 7. Reset de senha

### No `cluster-login`

```bash
sudo passwd nome_do_usuario
```

### Na Dell, se necessário

```bash
ssh lince2@gpu-a4000
sudo passwd nome_do_usuario
```

### Observação importante

As senhas são locais em cada máquina. Se você precisar sincronizar a senha de um admin remoto entre MSI e Dell, pode ser necessário fazer isso explicitamente.

---

## 8. Estrutura de pastas recomendada para cada usuário

Cada conta deve começar com esta estrutura:

```text
/home/usuario/
  projects/
  datasets/
  logs/
```

---

## 9. Comandos amigáveis para os usuários

Os usuários devem ter disponíveis:

- `run-a4000`
- `run-1660`
- `shell-a4000`
- `myjobs`
- `canceljob`
- `jobstatus`
- `joblog`
- `watchjob`

### Objetivo dos novos helpers

- `jobstatus <jobid>` → mostra status resumido
- `joblog <jobid>` → acompanha o log do job
- `watchjob <jobid>` → mostra status e últimas linhas do log juntos

### Verificar se existem

```bash
which run-a4000
which run-1660
which shell-a4000
which myjobs
which canceljob
which jobstatus
which joblog
which watchjob
```

---

## 10. Tailscale

### Objetivo

O Tailscale é o método principal para acessar o `cluster-login` de fora da rede local.

### Instalação no `cluster-login`

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Depois da autenticação, confira:

```bash
tailscale ip
tailscale status
```

### Onboarding de usuário no Tailscale

1. convidar o usuário para a tailnet do cluster
2. orientar instalação do Tailscale no notebook do usuário
3. entregar o IP ou nome Tailscale do `cluster-login`
4. testar `ssh usuario@100.x.y.z`

---

## 11. Conda central do cluster

O cluster usa uma instalação central do Conda em:

```text
/opt/miniconda3
```

### Regra de implantação

A instalação central deve existir **nos dois nós**, no mesmo caminho:

- MSI: `/opt/miniconda3`
- Dell: `/opt/miniconda3`

Isso é necessário porque os jobs enviados para a A4000 executam na Dell, e os wrappers usam esse caminho para acionar `conda run` quando o usuário tem um ambiente ativo.

### Instalação no MSI e na Dell

```bash
cd /tmp
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sudo bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3
```

### `.condarc` recomendado

```yaml
channels:
  - conda-forge
channel_priority: flexible
auto_activate_base: false
```

### Arquivos globais de perfil

Criar em ambos os nós:

```bash
/etc/profile.d/conda.sh
/etc/profile.d/conda-user-dirs.sh
```

Conteúdo recomendado de `/etc/profile.d/conda.sh`:

```bash
if [ -f /opt/miniconda3/etc/profile.d/conda.sh ]; then
    . /opt/miniconda3/etc/profile.d/conda.sh
fi
```

Conteúdo recomendado de `/etc/profile.d/conda-user-dirs.sh`:

```bash
export CONDA_PKGS_DIRS="$HOME/.conda/pkgs"
export CONDA_ENVS_PATH="$HOME/.conda/envs"
```

### Objetivo

- base Conda central administrada pelo sistema
- cache e ambientes por usuário no home
- evitar `NoWritablePkgsDirError`

---

## 12. Wrappers `run-a4000` e `run-1660`

Os wrappers devem:

- criar script temporário de job
- executar na partição correta
- salvar logs em `~/logs/slurm-%j.out`
- respeitar o ambiente Conda ativo do usuário, quando existir
- imprimir no final os comandos de acompanhamento

### Comportamento esperado

Se o usuário estiver com `conda activate meu_env` no momento da submissão, o wrapper deve tentar executar o job com algo como:

```bash
conda run --no-capture-output -p "$CONDA_PREFIX" ...
```

Ao submeter, o wrapper deve exibir algo como:

```text
Job enviado: 27
Log: /home/usuario/logs/slurm-27.out

Acompanhar:
  myjobs
  jobstatus 27
  joblog 27
  watchjob 27
```

### Objetivo

Permitir que o usuário tenha uma experiência próxima de "rodar Python como na própria máquina", sem precisar escrever um script separado para cada treino simples.

---

## 13. Helpers de acompanhamento de job

Além do `myjobs`, o cluster deve oferecer estes scripts em `/usr/local/bin/`:

### `jobstatus`

Uso:

```bash
jobstatus 27
```

Função:
- mostrar status resumido de um job específico via `squeue`

### `joblog`

Uso:

```bash
joblog 27
```

Função:
- seguir o log `~/logs/slurm-27.out`

### `watchjob`

Uso:

```bash
watchjob 27
```

Função:
- mostrar status e últimas linhas do log ao mesmo tempo, atualizando periodicamente

Esses helpers reduzem a necessidade de o usuário decorar caminhos e comandos longos.

---

## 14. Testes rápidos após manutenção

### Slurm

```bash
scontrol ping
sinfo
```

### Nó A4000

```bash
srun -p a4000 --gres=gpu:1 hostname
srun -p a4000 --gres=gpu:1 nvidia-smi
```

### Nó GTX 1660

```bash
srun -p gtx1660 --gres=gpu:1 hostname
srun -p gtx1660 --gres=gpu:1 nvidia-smi
```

### MUNGE

```bash
munge -n | unmunge
munge -n | ssh gpu-a4000 unmunge
```

### NFS

Na Dell:

```bash
mount | grep ' /home '
ls /home
```

### Tailscale

```bash
tailscale status
tailscale ip
```

### Conda

Em ambos os nós:

```bash
/opt/miniconda3/bin/conda --version
```

### Wrappers e helpers

Como usuário comum:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda create -n teste_env python=3.10 -y
conda activate teste_env
conda install tqdm -y
run-a4000 python -c "from tqdm import tqdm; import time; [time.sleep(0.01) for _ in tqdm(range(10))]"
```

Depois verificar:

```bash
joblog <jobid>
watchjob <jobid>
```

---

## 15. Rotina diária de checagem

```bash
sinfo
squeue
nvidia-smi
df -h
free -h
tailscale status
```

Na Dell:

```bash
ssh gpu-a4000 nvidia-smi
ssh gpu-a4000 df -h
ssh gpu-a4000 free -h
```

---

## 16. Como acompanhar jobs e usuários

```bash
squeue
squeue -u usuario
scontrol show job JOBID
```

### Observação

O accounting completo (`sacct`) pode estar indisponível ou limitado.
Não dependa dele como única fonte de diagnóstico.

---

## 17. Como orientar os usuários

Entregue sempre estas instruções básicas:

1. instale o Tailscale no computador local
2. conecte o Tailscale com a conta autorizada
3. entre por SSH no `cluster-login` usando o IP ou nome do Tailscale
4. inicialize o Conda com:
   ```bash
   source /opt/miniconda3/etc/profile.d/conda.sh
   source /etc/profile.d/conda-user-dirs.sh
   ```
5. crie seu ambiente
6. ative o ambiente antes de usar `run-a4000` ou `run-1660`
7. acompanhe logs em `~/logs`
8. use `jobstatus`, `joblog` e `watchjob` para acompanhar o job com mais conforto

---

## 18. Procedimento de onboarding de novo usuário

### Passo 1
Criar a conta:

```bash
sudo novo_usuario.sh novo_usuario lince2
sudo passwd novo_usuario
```

### Passo 2
Garantir acesso ao Tailscale do cluster.

### Passo 3
Enviar para o usuário:

- usuário
- senha inicial
- nome ou IP do Tailscale do `cluster-login`
- tutorial do usuário

### Passo 4
Pedir para testar:

- Tailscale
- SSH
- VS Code Remote-SSH
- `conda`
- `myjobs`
- `run-a4000 python -c "print('ok')"`

---

## 19. Procedimento de offboarding

### 1. Bloquear login

```bash
sudo usermod -L nome_do_usuario
```

### 2. Opcional: desativar shell

```bash
sudo usermod -s /usr/sbin/nologin nome_do_usuario
```

### 3. Conferir se há jobs rodando

```bash
squeue -u nome_do_usuario
```

### 4. Fazer backup do home, se necessário

```bash
sudo tar -czf /root/backup_nome_do_usuario.tar.gz /home/nome_do_usuario
```

### 5. Depois remover conta, se desejado

No login node:

```bash
sudo userdel -r nome_do_usuario
```

Na Dell, remover conta espelho:

```bash
ssh lince2@gpu-a4000 "sudo userdel nome_do_usuario || true"
ssh lince2@gpu-a4000 "sudo groupdel nome_do_usuario || true"
```

---

## 20. Arquivos importantes do sistema

### SSH

```text
/etc/ssh/sshd_config
/etc/ssh/sshd_config.d/cluster.conf
```

### NFS

```text
/etc/exports
/etc/fstab
```

### MUNGE

```text
/etc/munge/munge.key
```

### Slurm

```text
/etc/slurm/slurm.conf
/etc/slurm/cgroup.conf
/etc/slurm/gres.conf
```

### Conda

```text
/opt/miniconda3/
/opt/miniconda3/.condarc
/etc/profile.d/conda.sh
/etc/profile.d/conda-user-dirs.sh
```

### Scripts de usuário

```text
/usr/local/bin/run-a4000
/usr/local/bin/run-1660
/usr/local/bin/shell-a4000
/usr/local/bin/myjobs
/usr/local/bin/canceljob
/usr/local/bin/jobstatus
/usr/local/bin/joblog
/usr/local/bin/watchjob
```

### Script de admin

```text
/usr/local/sbin/novo_usuario.sh
```

---

## 21. Problemas comuns e solução

### 1. `conda: command not found`

Verifique se o usuário rodou:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
```

### 2. `NoWritablePkgsDirError`

Verifique se o usuário está com:

```bash
CONDA_PKGS_DIRS=$HOME/.conda/pkgs
CONDA_ENVS_PATH=$HOME/.conda/envs
```

### 3. `python: command not found` no job

O usuário provavelmente submeteu o job sem ambiente ativo, ou o wrapper não está respeitando `CONDA_PREFIX` corretamente.

### 4. `ModuleNotFoundError`

O pacote não está instalado no ambiente do usuário.

### 5. Job falha com `Syntax error: Unterminated quoted string`

O wrapper está montando o comando de forma frágil. Recrie o wrapper para usar script temporário + `exec "$@"`.

### 6. `novo_usuario.sh` cria o usuário no MSI mas não na Dell

Verifique:

- se o admin remoto da Dell consegue SSH
- se esse admin remoto está no `sudo`
- se o script está usando `scp` + `sudo bash` remoto, e não `sudo bash -s` via stdin
- se o grupo primário remoto do usuário está sendo criado antes do `useradd`

### 7. Usuário não consegue acessar de casa

Verifique:

```bash
tailscale status
tailscale ip
```

Confirme se:

- o notebook do usuário está na mesma tailnet
- o `cluster-login` aparece online
- o usuário está usando o IP ou nome do Tailscale

---

## 22. Checklist de manutenção semanal

### Sistema

- [ ] `apt update` e revisão de pacotes
- [ ] checar espaço em disco
- [ ] checar uso de memória
- [ ] checar logs do systemd
- [ ] checar integridade do MUNGE
- [ ] checar NFS
- [ ] checar Tailscale
- [ ] checar Conda nos dois nós

### Cluster

- [ ] `sinfo`
- [ ] `squeue`
- [ ] teste `srun` na A4000
- [ ] teste `srun` na 1660
- [ ] conferir `nvidia-smi` nas duas máquinas
- [ ] conferir `run-a4000`, `run-1660`, `jobstatus`, `joblog` e `watchjob`

### Usuários

- [ ] contas ativas conferidas
- [ ] usuários antigos revisados
- [ ] permissões corretas no `/home`
- [ ] sem arquivos soltos em locais indevidos

---

## 23. Checklist de entrega final do ambiente

O cluster está pronto quando:

- [ ] usuários conseguem acessar o `cluster-login` por Tailscale + SSH
- [ ] usuários conseguem usar VS Code Remote-SSH pelo Tailscale
- [ ] `/home` aparece igual nos dois nós
- [ ] `/opt/miniconda3` existe nos dois nós
- [ ] `run-a4000` envia jobs corretamente
- [ ] `run-1660` envia jobs corretamente
- [ ] `myjobs` funciona
- [ ] `canceljob` funciona
- [ ] `jobstatus` funciona
- [ ] `joblog` funciona
- [ ] `watchjob` funciona
- [ ] `shell-a4000` abre sessão interativa
- [ ] `srun -p a4000 --gres=gpu:1 nvidia-smi` funciona
- [ ] `srun -p gtx1660 --gres=gpu:1 nvidia-smi` funciona

---

## 24. Resumo executivo

### O usuário final faz:
- Tailscale
- SSH
- VS Code remoto
- Conda
- `run-a4000`
- `run-1660`
- `myjobs`
- `jobstatus`
- `joblog`
- `watchjob`

### O administrador faz:
- cria contas
- mantém Slurm, SSH, MUNGE, NFS, Conda e Tailscale
- monitora GPU, RAM e disco
- intervém quando houver uso fora da fila
- mantém o cluster simples e previsível

---

Fim do tutorial do administrador.
