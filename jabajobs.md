# JABA JOBS - guia de uso

Este guia explica como baixar, instalar e usar o JABA JOBS.

O JABA JOBS e uma ferramenta para acessar o cluster por SSH, acompanhar jobs, visualizar logs, receber alertas de parada ou erro e submeter experimentos para as filas disponiveis.

## 1. Versao atual

- Versao: `v1.0.0`
- Build: `1`
- Data de publicacao: `09/06/2026`
- Plataformas: Windows e Android

Arquivos de download:

- Windows: `JABA-JOBS-Windows-v1.0.0.zip`
- Android: `JABA-JOBS-Android-v1.0.0.apk`

## 2. Antes de usar

Voce precisa ter:

- VPN UNESP ou Tailscale configurado, conforme orientacao do administrador do cluster;
- usuario Linux do cluster;
- senha SSH;
- IP ou nome do `cluster-login`;
- app JABA JOBS instalado ou extraido.

Importante: a senha SSH nao e salva em disco pelo app. Se voce marcar a opcao de lembrar dados, apenas host e usuario ficam salvos.

## 3. Instalacao no Windows

1. Baixe `JABA-JOBS-Windows-v1.0.0.zip`.
2. Extraia o ZIP inteiro em uma pasta do seu computador.
3. Abra `jaba_jobs.exe`.
4. Informe host, usuario e senha SSH.

No Windows, nao execute apenas o `.exe` isolado. O app precisa das DLLs, assets e arquivos que ficam junto dele dentro da pasta extraida.

Se o Windows SmartScreen mostrar um aviso, confirme que o arquivo foi baixado da pagina oficial do projeto antes de executar.

## 4. Instalacao no Android

1. Baixe `JABA-JOBS-Android-v1.0.0.apk`.
2. Se o Android pedir, permita a instalacao de apps de fonte externa.
3. Abra a VPN UNESP ou o Tailscale e confirme que a conexao esta ativa.
4. Abra o JABA JOBS.
5. Informe host, usuario e senha SSH.

Se o app nao conectar, teste primeiro se o celular consegue acessar o cluster pela mesma VPN/rede indicada pelo administrador.

## 5. Primeiro acesso

1. Abra a VPN indicada para acesso ao cluster e confirme que ela esta conectada.
2. Abra o JABA JOBS.
3. Na tela de login, preencha:
   - `Host`: IP ou nome do `cluster-login`;
   - `Usuario`: seu usuario Linux do cluster;
   - `Senha`: sua senha SSH.
4. Marque `Lembrar host e usuario` somente se estiver usando um dispositivo confiavel.
5. Clique em `Conectar`.

Se a conexao falhar com timeout, normalmente o app nao conseguiu chegar na porta SSH do cluster. Confira a VPN, o host informado e se seu usuario esta autorizado.

## 6. Telas principais no Windows

### Dashboard

Mostra um resumo da sessao SSH e do estado do cluster:

- usuario conectado;
- hostname remoto;
- uptime;
- memoria;
- disco em `/home`;
- carga do sistema;
- jobs recentes.

Use `Atualizar` ou deixe `Auto` ligado para renovar os dados automaticamente.

### Jobs

Use esta tela para:

- listar seus jobs com `Ver meus jobs`;
- selecionar um job;
- abrir o log do job selecionado;
- cancelar um job quando necessario.

Antes de cancelar, confira se o ID esta correto. Cancelar um job interrompe o experimento.

### Logs

Use a tela `Logs` para acompanhar um job especifico.

Fluxo recomendado:

1. Informe ou selecione o `jobid`.
2. Use `Status` para ver o estado atual.
3. Use `Joblog` para abrir o log.
4. Use `Watch` para acompanhar status e log juntos.
5. Ative `Seguir` para manter o log rolando.
6. Ative `Notificar` para receber aviso quando o job parar ou quando aparecerem erros comuns no log.

O app pode avisar sobre parada, falha, cancelamento, timeout, OOM e padroes como `Traceback`, `Exception`, `CUDA error`, `out of memory`, `failed`, `falha` e `erro`.

### Submit

Use `Submit` para enviar um novo job para a fila.

Preencha:

- diretorio remoto do projeto, por exemplo `~/projects/meu_modelo`;
- ambiente Conda, se quiser ativar um ambiente antes de rodar;
- particao: `a4000` para treinos maiores ou `gtx1660` para testes menores;
- comando de uma linha, por exemplo `python train.py --epochs 100`.

Exemplo para A4000:

```bash
python train.py --epochs 100 --batch-size 32
```

Exemplo para GTX 1660:

```bash
python train.py --epochs 20 --batch-size 8
```

Por baixo, o app usa os wrappers do cluster, como `run-a4000` e `run-1660`. O treino continua no cluster mesmo se voce fechar o computador depois que o job foi submetido corretamente.

### Admin

A aba `Admin` aparece apenas para usuarios detectados como administradores, por grupo Linux `clusteradmins` ou `sudo`.

Ela serve para:

- checar Slurm;
- ver particoes e nos;
- listar jobs por usuario;
- consultar GPU;
- rodar diagnosticos;
- criar usuario via `clusterctl`, se o helper estiver instalado.

## 7. Uso no Android

No celular, a interface fica mais compacta e mostra principalmente:

- `Monitor`: jobs, logs, progresso e notificacao de parada/erro;
- `Config`: dados da sessao e preferencias basicas.

Antes de abrir o app no Android:

1. Conecte na VPN indicada para o cluster.
2. Confirme que o celular esta autorizado a acessar o `cluster-login`.
3. Abra o JABA JOBS.
4. Conecte usando o IP ou nome do `cluster-login`.

Se der timeout, teste o SSH no proprio Android com Termux ou outro cliente SSH. Se o SSH tambem falhar, o problema esta na VPN, rota, autorizacao do dispositivo ou SSH do servidor.

## 8. Boas praticas para usuarios

- Nao rode treino pesado diretamente no terminal do `cluster-login`.
- Use `run-a4000`, `run-1660` ou a tela `Submit` do app.
- Use a GTX 1660 para testes menores.
- Use a A4000 para treinos mais pesados.
- Mantenha seus projetos em `~/projects`.
- Mantenha datasets em `~/datasets`.
- Confira logs em `~/logs`.
- Ative o ambiente Conda correto antes de submeter, quando estiver usando terminal.
- Cancele jobs que voce sabe que nao precisa mais.
- Nunca compartilhe sua senha SSH.

## 9. Problemas comuns

### Nao conecta

Confira:

- A VPN esta aberta e conectada?
- O host informado e o IP ou nome correto do `cluster-login`?
- O usuario e a senha estao corretos?
- O dispositivo esta autorizado a acessar a rede do cluster?
- O SSH do `cluster-login` esta disponivel?

### Senha incorreta

Peca ao administrador para redefinir sua senha no cluster.

### Job nao aparece

Clique em `Ver meus jobs` ou atualize a dashboard. Se o job terminou muito rapido, veja o log em `~/logs/slurm-<jobid>.out`.

### Log vazio

O job pode ainda nao ter iniciado, pode ter terminado sem imprimir nada ou o ID pode estar errado. Confira o status do job.

### `run-a4000` ou `run-1660` nao existe

Os wrappers do cluster nao estao instalados ou nao estao no `PATH`. Avise o administrador.

### Ambiente Conda nao encontrado

Confira se o ambiente existe no cluster e se o nome foi digitado corretamente.

## 10. Changelog

### JABA JOBS v1.0.0

Primeira versao publica do JABA JOBS para Windows e Android.

Novidades:

- Dashboard com estado da conexao, memoria, disco, carga e jobs.
- Listagem de jobs do usuario.
- Visualizacao de logs por `joblog` e `watchjob`.
- Alertas quando um job para ou quando o log mostra erros comuns.
- Submissao de jobs para `a4000` e `gtx1660`.
- Interface mobile com foco em monitoramento e logs.
- Aba administrativa para usuarios autorizados.

Requisitos da versao:

- VPN UNESP ou Tailscale configurado.
- Conta SSH no cluster.
- Host ou IP do `cluster-login`.
- Wrappers do cluster configurados: `run-a4000`, `run-1660`, `myjobs`, `joblog`, `watchjob` e `canceljob`.
