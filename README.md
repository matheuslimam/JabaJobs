# JABA JOBS

JABA JOBS é um aplicativo desktop Flutter para Windows que conecta ao nó de login do cluster por SSH, usando o fluxo oficial Tailscale + SSH, e mostra uma dashboard visual para alunos e administradores.

O MVP foi pensado para o cenário:

- `cluster-login`: nó de login, `/home`, controlador Slurm e partição `gtx1660`
- `gpu-a4000`: nó de treino principal e partição `a4000`
- wrappers remotos: `run-a4000`, `run-1660`, `myjobs`, `canceljob`, `joblog`, `watchjob`
- logs em `~/logs/slurm-<jobid>.out`

## Funcionalidades

- Modo mobile responsivo focado em Monitor/Logs
- Seletor compacto de jobs em tela estreita
- Alerta in-app, som do sistema e vibracao quando o job selecionado sai da fila/para de rodar ou quando o log mostra padroes comuns de erro

- Login SSH com host, usuário e senha
- Persistência opcional apenas de host e usuário
- Senha mantida apenas em memória
- Detecção de administrador por grupo Linux `clusteradmins` ou `sudo`
- Dashboard do usuário com conexão, uptime, RAM, disco `/home`, carga e jobs
- Lista de jobs do usuário via `myjobs` ou fallback `squeue`
- Visualização e atualização de logs
- Status/log/watch usando `jobstatus`, `joblog` e `watchjob` quando disponíveis
- Acompanhamento visual estilo `tqdm` na aba Logs, com a lesma da logo avançando pelo progresso detectado
- Cancelamento de jobs por `canceljob` ou fallback `scancel`
- Submissão com diretório remoto, Conda opcional e `run-a4000 <comando>` ou `run-1660 <comando>`
- Aba Admin com `scontrol ping`, `sinfo`, nós, todos os jobs, jobs por usuário e `nvidia-smi`
- Diagnóstico admin baseado no tutorial: helpers, Tailscale, Conda, MUNGE, NFS, Slurm e logs systemd
- UI inicial para criação de usuário integrada a `clusterctl create-user` quando existir
- Helper remoto seguro `clusterctl` com exemplo instalável em `scripts/clusterctl`

## Arquitetura

O app evita espalhar comandos SSH pela UI:

- `lib/services/ssh_service.dart`: sessão SSH, timeout e execução remota
- `lib/services/cluster_parser.dart`: parsing de `squeue`, `sinfo`, `free -h` e `df -h`
- `lib/repositories/cluster_repository.dart`: fonte de dados do cluster
- `lib/state/cluster_app_state.dart`: estado da aplicação e timers
- `lib/ui/pages`: telas do aplicativo
- `lib/models`: modelos fortemente tipados

Para ações administrativas, o app prioriza `sudo -n /usr/local/sbin/clusterctl`. Isso evita prompts interativos de `sudo`, `passwd` ou `ssh gpu-a4000` dentro do app desktop.

## Instalando o `clusterctl` no cluster-login

O repositório inclui um helper-base em `scripts/clusterctl`. Instale no `cluster-login`:

```bash
sudo install -o root -g root -m 0755 scripts/clusterctl /usr/local/sbin/clusterctl
sudo install -o root -g root -m 0440 scripts/clusterctl.sudoers /etc/sudoers.d/clusterctl
sudo visudo -cf /etc/sudoers.d/clusterctl
```

O sudoers esperado é:

```sudoers
%clusteradmins ALL=(root) NOPASSWD: /usr/local/sbin/clusterctl
```

Teste antes de usar pelo app:

```bash
sudo -n /usr/local/sbin/clusterctl health
sudo -n /usr/local/sbin/clusterctl gpu-info a4000
sudo -n /usr/local/sbin/clusterctl create-user teste_app lince2
```

Para `gpu-info a4000`, o helper precisa de uma forma não interativa de consultar a Dell, por exemplo uma chave SSH interna configurada para o usuário/root que executa o helper. Login manual com senha em `ssh lince2@gpu-a4000` não basta para automação.

## Rodando em desenvolvimento

Pré-requisitos:

- Flutter instalado com suporte a Windows Desktop
- Visual Studio com workload “Desktop development with C++”
- Tailscale conectado na máquina Windows
- Acesso SSH ao `cluster-login`

Comandos:

```powershell
flutter pub get
flutter run -d windows
```

Para testar a experiencia mobile sem gerar APK, rode em uma janela estreita ou use um target Android/iOS quando esses targets forem adicionados ao projeto Flutter. No modo mobile, a navegacao mostra apenas:

- `Monitor`: jobs, log, progresso e chave `Notificar parada/erro`
- `Config`: sessao atual e preferencias basicas

O monitor verifica o job selecionado a cada 15 segundos enquanto o app esta aberto e conectado ao SSH. Ele atualiza `myjobs`, le o log `~/logs/slurm-<jobid>.out` e avisa quando:

- o job estava ativo e deixou de aparecer/rodar na fila Slurm
- o estado Slurm indica falha/cancelamento/timeout/OOM
- o log contem sinais como `Traceback`, `Exception`, `CUDA error`, `out of memory`, `failed`, `falha` ou `erro`

Observacao: esta implementacao usa alerta dentro do app, som do sistema e vibracao. Para notificacoes push/background com o app fechado, adicione uma camada nativa como `flutter_local_notifications` + permissao Android/iOS e um servico de background.

### Timeout SSH no Android com IP Tailscale

Se o APK mostrar `SocketException: Connection timed out` para um host `100.x.x.x`, o app nao chegou na porta SSH. Isso normalmente nao e senha errada; e caminho de rede.

No celular:

- Instale e abra o app Tailscale.
- Entre no mesmo tailnet usado pelo `cluster-login`.
- Confirme que a VPN do Tailscale esta ativa no Android.
- Verifique no admin do Tailscale se o dispositivo Android foi autorizado e se as ACLs permitem acesso ao `cluster-login:22`.
- Teste no proprio Android com Termux ou outro cliente SSH: `ssh usuario@100.104.26.64`. Se tambem der timeout, o problema esta no Tailscale/rota/ACL/sshd, nao no app.

No `cluster-login`, confirme que o SSH esta escutando:

```bash
sudo ss -lntp | grep ':22'
```

Na tela inicial, informe:

- Host: IP Tailscale do login node, por exemplo `100.104.26.64`
- Usuário: usuário Linux do cluster
- Senha: senha SSH

## Gerando o `.exe` para Windows

```powershell
flutter build windows --release
```

O executável fica em:

```text
build\windows\x64\runner\Release\jaba_jobs.exe
```

Para distribuir, envie a pasta `Release` inteira, não apenas o `.exe`, porque ela contém DLLs e assets necessários do Flutter.

## Comandos remotos usados

Conexão e identidade:

```bash
hostname
whoami
id -nG
```

Saúde básica:

```bash
uptime -p || uptime
free -h
df -h /home
cat /proc/loadavg
```

Jobs:

```bash
myjobs
squeue -u <usuario> -h -o "%i|%P|%j|%u|%T|%M|%D|%R"
squeue -h -o "%i|%P|%j|%u|%T|%M|%D|%R"
canceljob <jobid>
scancel <jobid>
```

Logs:

```bash
jobstatus <jobid>
timeout 6s joblog <jobid>
timeout 7s watchjob <jobid>
tail -n 240 ~/logs/slurm-<jobid>.out
```

Submit:

```bash
cd <diretorio_remoto>
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate <ambiente_opcional>
run-a4000 <comando>
run-1660 <comando>
```

Admin:

```bash
sudo -n /usr/local/sbin/clusterctl health
sudo -n /usr/local/sbin/clusterctl gpu-info a4000
scontrol ping
sinfo -h -o "%P|%a|%l|%D|%t|%N"
sinfo -N -h -o "%N|%T|%P|%c|%m|%G"
nvidia-smi
ssh -o BatchMode=yes -o ConnectTimeout=5 gpu-a4000 nvidia-smi
srun -p a4000 --gres=gpu:1 nvidia-smi
srun -p gtx1660 --gres=gpu:1 nvidia-smi
scontrol show nodes
tailscale ip
tailscale status
munge -n | unmunge
munge -n | ssh gpu-a4000 unmunge
journalctl -u slurmctld -n 80 --no-pager
journalctl -u slurmd -n 80 --no-pager
journalctl -u munge -n 80 --no-pager
journalctl -u ssh -n 80 --no-pager
```

Criação de usuário:

```bash
sudo -n /usr/local/sbin/clusterctl create-user <usuario> <admin_dell>
sudo passwd <usuario>
```

## Adaptando ao cluster

Os pontos mais prováveis de customização estão em:

- `AdminDetector`: regra de admin por grupo Linux
- `ClusterRepository.getMyJobs`: preferência por `myjobs`
- `ClusterRepository.submitJob`: mapeamento `a4000 -> run-a4000` e `gtx1660 -> run-1660`
- `ClusterRepository.getGpuInfo`: forma de consultar a GPU do nó `gpu-a4000`
- `ClusterRepository.getDiagnostics`: checklist administrativo do ambiente
- `ClusterRepository.runCreateUserHelper`: criação real via `sudo -n /usr/local/sbin/clusterctl create-user`
- `ClusterParser`: formatos de saída de `myjobs`, `squeue`, `sinfo`, `free` e `df`

## Segurança do MVP

- A senha SSH não é salva em disco
- Host e usuário só são salvos se o checkbox for marcado
- `jobId` é validado antes de comandos de log/cancelamento
- Submit aceita apenas comando de uma linha e limita tamanho
- A criação de usuário chama `sudo -n /usr/local/sbin/clusterctl create-user`; se sudoers/helper não estiverem configurados, mostra erro amigável
- O app não envia senha inicial por `passwd`; essa etapa continua explícita e administrativa

## Próximos passos naturais

- Armazenamento seguro de credenciais com cofre do sistema
- Helper remoto `clusterctl`
- Terminal embutido
- Upload de arquivos
- Gerenciamento de ambientes Conda
- Empacotador/instalador Windows
