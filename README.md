<p align="center">
  <img src="jenasolo.png" alt="JABA JOBS" width="220" />
</p>

<h1 align="center">JABA JOBS</h1>

<p align="center">
  Dashboard Flutter para monitorar jobs, logs e recursos de um cluster Slurm via SSH.
</p>

<p align="center">
  <a href="https://github.com/matheuslimam/Lince_cluster_app/releases">
    <img alt="Release" src="https://img.shields.io/badge/release-v1.0.0-00B879?style=for-the-badge" />
  </a>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img alt="Platforms" src="https://img.shields.io/badge/Windows%20%7C%20Android-supported-111B21?style=for-the-badge" />
</p>

<p align="center">
  <a href="https://matheuslimam.github.io/Lince_cluster_app/"><strong>Pagina de download</strong></a>
  |
  <a href="jabajobs.md"><strong>Guia de uso</strong></a>
  |
  <a href="https://github.com/matheuslimam/Lince_cluster_app/releases"><strong>Releases</strong></a>
</p>

---

## Visao geral

O **JABA JOBS** e uma ferramenta para alunos, pesquisadores e administradores acompanharem jobs de treinamento em um cluster Slurm sem precisar decorar comandos longos no terminal.

O app conecta ao no de login por SSH, consulta jobs, mostra logs, detecta progresso estilo `tqdm`, envia alertas de parada ou erro e permite submeter experimentos para as filas configuradas do cluster.

O MVP foi desenhado para este ambiente:

- `cluster-login`: no de login, `/home`, controlador Slurm e particao `gtx1660`;
- `gpu-a4000`: no de treino principal e particao `a4000`;
- wrappers remotos: `run-a4000`, `run-1660`, `myjobs`, `canceljob`, `joblog`, `watchjob`;
- logs em `~/logs/slurm-<jobid>.out`;
- acesso de rede pela VPN UNESP.

## Downloads

A versao atual e **v1.0.0**.

| Plataforma | Arquivo | Link |
| --- | --- | --- |
| Windows | `JABA-JOBS-Windows-v1.0.0.zip` | [Baixar ZIP](https://github.com/matheuslimam/Lince_cluster_app/releases/download/v1.0.0/JABA-JOBS-Windows-v1.0.0.zip) |
| Android | `JABA-JOBS-Android-v1.0.0.apk` | [Baixar APK](https://github.com/matheuslimam/Lince_cluster_app/releases/download/v1.0.0/JABA-JOBS-Android-v1.0.0.apk) |

No Windows, extraia o ZIP inteiro antes de abrir `jaba_jobs.exe`. O executavel depende das DLLs, assets e arquivos que ficam ao lado dele.

## Funcionalidades

- Login SSH com host, usuario e senha.
- Persistencia opcional apenas de host e usuario.
- Senha mantida somente em memoria.
- Dashboard com conexao, uptime, RAM, disco `/home`, carga e jobs.
- Lista de jobs do usuario via `myjobs` ou fallback para `squeue`.
- Visualizacao de logs por `joblog`, `watchjob` ou leitura direta de `~/logs`.
- Acompanhamento visual de progresso estilo `tqdm`.
- Alertas in-app, som do sistema e vibracao quando o job selecionado para ou quando o log mostra erros comuns.
- Cancelamento de jobs por `canceljob` ou fallback para `scancel`.
- Submissao com diretorio remoto, Conda opcional e wrappers `run-a4000` / `run-1660`.
- Modo mobile responsivo com foco em `Monitor` e `Config`.
- Aba administrativa para usuarios autorizados.
- Diagnosticos administrativos de Slurm, GPU, Conda, MUNGE, NFS e logs systemd.
- Criacao de usuarios via helper seguro `clusterctl`, quando configurado.

## Requisitos para usar

Para usar o app, o usuario precisa de:

- VPN UNESP configurada;
- conta Linux no cluster;
- senha SSH;
- IP ou nome do `cluster-login`;
- wrappers do cluster disponiveis no servidor, como `run-a4000`, `run-1660`, `myjobs`, `joblog`, `watchjob` e `canceljob`.

O app nao fornece acesso ao cluster por conta propria. Ele usa as credenciais e a rede autorizada pelo administrador.

## Fluxo de uso

1. Abra a VPN indicada para acesso ao cluster.
2. Abra o JABA JOBS.
3. Informe host, usuario e senha SSH.
4. Acompanhe seus jobs na dashboard ou na tela `Jobs`.
5. Abra logs pela tela `Logs` ou pelo modo `Monitor` no Android.
6. Submeta novos experimentos pela tela `Submit`.

Para treinos longos, use sempre a fila do cluster. Evite rodar treinamento pesado diretamente no terminal do `cluster-login`.

## Telas do app

| Tela | Objetivo |
| --- | --- |
| `Dashboard` | Resumo da conexao, saude do cluster e jobs recentes. |
| `Jobs` | Listagem, abertura de log e cancelamento de jobs. |
| `Logs` | Status, log, watch e notificacoes de parada ou erro. |
| `Submit` | Submissao de comandos para `a4000` ou `gtx1660`. |
| `Admin` | Diagnosticos e acoes administrativas para usuarios autorizados. |
| `Config` | Informacoes da sessao e preferencias basicas. |
| `Monitor` | Interface mobile compacta para jobs, logs e alertas. |

## Arquitetura

O app separa UI, estado, repositorio e execucao SSH para evitar comandos espalhados pelas telas.

```text
lib/
  core/                 Utilidades e excecoes
  models/               Modelos tipados do dominio
  repositories/         Acesso de alto nivel ao cluster
  services/             SSH, preferencias, parsing e deteccao admin
  state/                Estado global da aplicacao
  ui/pages/             Telas do app
  ui/widgets/           Componentes visuais reutilizaveis
```

Componentes principais:

- `lib/services/ssh_service.dart`: sessao SSH, timeout e execucao remota;
- `lib/services/cluster_parser.dart`: parsing de `squeue`, `sinfo`, `free -h`, `df -h` e logs;
- `lib/repositories/cluster_repository.dart`: fonte de dados e comandos do cluster;
- `lib/state/cluster_app_state.dart`: estado da aplicacao, timers e monitoramento;
- `lib/services/admin_detector.dart`: deteccao de administrador por grupo Linux.

## Seguranca

- A senha SSH nao e salva em disco.
- Host e usuario so sao salvos se o usuario marcar a opcao de lembrar.
- `jobId` e validado antes de comandos de log e cancelamento.
- A submissao aceita comando de uma linha e limita tamanho.
- Acoes administrativas priorizam `sudo -n /usr/local/sbin/clusterctl`.
- O app nao executa prompts interativos de `passwd`, `sudo` ou SSH aninhado dentro da interface.

## Helper administrativo `clusterctl`

Para acoes administrativas sem prompts interativos, o app pode usar:

```bash
sudo -n /usr/local/sbin/clusterctl
```

O repositorio inclui um helper-base em `scripts/clusterctl`.

Instalacao sugerida no `cluster-login`:

```bash
sudo install -o root -g root -m 0755 scripts/clusterctl /usr/local/sbin/clusterctl
sudo install -o root -g root -m 0440 scripts/clusterctl.sudoers /etc/sudoers.d/clusterctl
sudo visudo -cf /etc/sudoers.d/clusterctl
```

Entrada sudoers esperada:

```sudoers
%clusteradmins ALL=(root) NOPASSWD: /usr/local/sbin/clusterctl
```

Testes recomendados:

```bash
sudo -n /usr/local/sbin/clusterctl health
sudo -n /usr/local/sbin/clusterctl gpu-info a4000
sudo -n /usr/local/sbin/clusterctl create-user teste_app <admin_remoto>
```

## Desenvolvimento

Pre-requisitos:

- Flutter com suporte a Windows Desktop;
- Visual Studio com workload `Desktop development with C++`;
- Android Studio/SDK para gerar APK;
- acesso SSH ao `cluster-login` para testes reais.

Instalacao das dependencias:

```powershell
flutter pub get
```

Rodar no Windows:

```powershell
flutter run -d windows
```

Rodar testes e analise:

```powershell
flutter analyze
flutter test
```

## Build de release

Windows:

```powershell
flutter build windows --release
```

Saida:

```text
build\windows\x64\runner\Release\jaba_jobs.exe
```

Para distribuir, compacte a pasta `Release` inteira.

Android:

```powershell
flutter build apk --release
```

Saida:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## Comandos remotos usados

Identidade e saude:

```bash
hostname
whoami
id -nG
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

Submissao:

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
scontrol show nodes
journalctl -u slurmctld -n 80 --no-pager
journalctl -u slurmd -n 80 --no-pager
journalctl -u munge -n 80 --no-pager
journalctl -u ssh -n 80 --no-pager
```

## Documentacao

- [Guia de uso](jabajobs.md)
- [Pagina de download](index.html)
- [Tutorial do usuario](tutorial_usuario_atualizado_v4.md)

## Roadmap

- Armazenamento seguro de credenciais com cofre do sistema.
- Notificacoes nativas/background.
- Upload de arquivos.
- Terminal embutido.
- Gerenciamento de ambientes Conda.
- Instalador Windows assinado.
- Publicacao formal em lojas quando necessario.

## Licenca

Este projeto ainda nao declara uma licenca publica. Antes de redistribuir ou reutilizar codigo em outro contexto, defina uma licenca no repositorio.
