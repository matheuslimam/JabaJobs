# JABA JOBS - guia de uso e distribuicao

Este guia explica como usar o JABA JOBS e como disponibilizar o app para outras pessoas em Windows (`.exe`) e Android (`.apk`).

O JABA JOBS e uma interface Flutter para acompanhar e submeter jobs no cluster por SSH, usando o acesso oficial por Tailscale. Ele ajuda usuarios a ver jobs, ler logs, receber alertas de parada/erro e enviar comandos para as filas `a4000` e `gtx1660`.

## 1. Antes de usar

Voce precisa ter:

- VPN UNESP configurado
- usuario Linux do cluster;
- senha SSH;
- IP ou nome Tailscale do `cluster-login`, por exemplo `100.x.y.z`;
- app JABA JOBS instalado ou extraido.

Importante: a senha SSH nao e salva em disco pelo app. Se voce marcar a opcao de lembrar dados, apenas host e usuario ficam salvos.

## 2. Primeiro acesso

1. Abra o vpn e confirme que ele esta conectado.
2. Abra o JABA JOBS.
3. Na tela de login, preencha:
   - `Host`: IP ou nome Tailscale do `cluster-login`;
   - `Usuario`: seu usuario Linux do cluster;
   - `Senha`: sua senha SSH.
4. Marque `Lembrar host e usuario` somente se estiver usando um dispositivo confiavel.
5. Clique em `Conectar`.

Se a conexao falhar com timeout em um IP `100.x.x.x`, normalmente o celular ou computador nao esta chegando ao SSH pelo Tailscale. Confira se a VPN do Tailscale esta ativa, se o dispositivo foi autorizado na tailnet e se as ACLs permitem acesso ao `cluster-login:22`.

## 3. Telas principais no Windows

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

## 4. Uso no Android

No celular, a interface fica mais compacta e mostra principalmente:

- `Monitor`: jobs, logs, progresso e notificacao de parada/erro;
- `Config`: dados da sessao e preferencias basicas.

Antes de abrir o app no Android:

1. Instale o Tailscale no celular.
2. Entre na mesma tailnet do cluster.
3. Confirme que a VPN do Tailscale esta ativa.
4. Abra o JABA JOBS e conecte usando o IP ou nome Tailscale do `cluster-login`.

Se der timeout, teste o SSH no proprio Android com Termux ou outro cliente SSH. Se o SSH tambem falhar, o problema esta na rota Tailscale, autorizacao do dispositivo, ACL ou SSH do servidor.

## 5. Boas praticas para usuarios

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

## 6. Problemas comuns

### Nao conecta

Confira:

- Tailscale esta aberto e conectado?
- O host informado e o IP ou nome Tailscale correto?
- O usuario e a senha estao corretos?
- O dispositivo foi autorizado na tailnet?
- O SSH do `cluster-login` esta escutando na porta 22?

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

## 7. Como gerar o EXE para Windows

Na raiz do projeto, rode:

```powershell
flutter pub get
flutter build windows --release
```

O build final fica em:

```text
build\windows\x64\runner\Release\
```

O executavel principal e:

```text
build\windows\x64\runner\Release\jaba_jobs.exe
```

Para distribuir no Windows, envie a pasta `Release` inteira compactada em `.zip`. Nao envie apenas o `.exe`, porque o app Flutter precisa das DLLs, assets e da pasta `data`.

Sugestao de nome:

```text
JABA-JOBS-Windows-v1.0.0.zip
```

Antes de publicar, teste o `.zip` em uma maquina Windows limpa:

1. extraia o `.zip`;
2. abra `jaba_jobs.exe`;
3. conecte no Tailscale;
4. faca login no cluster;
5. teste Dashboard, Jobs, Logs e Submit.

Observacao: sem assinatura de codigo, o Windows SmartScreen pode mostrar aviso. Para distribuicao interna isso pode ser aceitavel, desde que os usuarios baixem de uma fonte confiavel. Para distribuicao mais ampla, considere assinar o executavel com um certificado de code signing.

## 8. Como gerar o APK para Android

Na raiz do projeto, rode:

```powershell
flutter pub get
flutter build apk --release
```

O APK fica em:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Sugestao de nome:

```text
JABA-JOBS-Android-v1.0.0.apk
```

Para instalar fora da Play Store, o usuario precisa permitir instalacao de apps desconhecidos para o navegador, gerenciador de arquivos ou app pelo qual ele recebeu o APK.

Antes de publicar, teste em um Android real:

1. instale o APK;
2. abra o Tailscale;
3. conecte na tailnet do cluster;
4. abra o JABA JOBS;
5. faca login usando o IP Tailscale do `cluster-login`;
6. teste Monitor, Logs e Config.

Para publicar na Google Play, normalmente voce deve gerar um Android App Bundle:

```powershell
flutter build appbundle --release
```

O arquivo gerado fica em:

```text
build\app\outputs\bundle\release\app-release.aab
```

Para Play Store ou distribuicao profissional, configure assinatura de release e troque identificadores genericos como `com.example` por um package name real do projeto.

## 9. Onde disponibilizar os arquivos

Opcoes simples:

- GitHub Releases: melhor opcao para projeto versionado. Crie uma release, anexe o `.zip` do Windows e o `.apk` do Android, escreva changelog e instrucoes.
- Google Drive ou OneDrive: bom para distribuicao rapida para uma turma ou laboratorio. Use link com acesso controlado.
- Pagina simples do projeto: uma pagina com botoes de download, versao atual, data, requisitos e changelog.

Opcoes mais formais:

- Microsoft Store: melhor para distribuicao Windows publica, mas exige empacotamento e conta de desenvolvedor.
- Google Play: melhor para Android publico, mas exige conta de desenvolvedor, assinatura, politicas da loja e envio do `.aab`.

Para uso interno do laboratorio, a forma mais pratica costuma ser:

1. criar uma release no GitHub;
2. anexar `JABA-JOBS-Windows-v1.0.0.zip`;
3. anexar `JABA-JOBS-Android-v1.0.0.apk`;
4. colocar no texto da release os requisitos: Tailscale, usuario SSH, senha e host do `cluster-login`;
5. avisar que o Windows deve extrair o ZIP inteiro antes de abrir o app.

## 10. Checklist antes de liberar uma versao

- [ ] Atualizar `version` no `pubspec.yaml`.
- [ ] Rodar `flutter pub get`.
- [ ] Gerar build Windows release.
- [ ] Gerar APK Android release.
- [ ] Testar Windows em uma maquina diferente.
- [ ] Testar Android em aparelho real.
- [ ] Confirmar que o Tailscale conecta.
- [ ] Confirmar login SSH no app.
- [ ] Testar listagem de jobs.
- [ ] Testar abertura de logs.
- [ ] Testar submissao simples.
- [ ] Compactar a pasta `Release` inteira para Windows.
- [ ] Renomear artefatos com nome e versao.
- [ ] Gerar hash SHA256 dos arquivos publicados.

Comandos para gerar hash no Windows:

```powershell
Get-FileHash .\JABA-JOBS-Windows-v1.0.0.zip -Algorithm SHA256
Get-FileHash .\JABA-JOBS-Android-v1.0.0.apk -Algorithm SHA256
```

Publique esses hashes junto dos downloads para quem baixar poder conferir a integridade dos arquivos.
