# Tutorial de Uso do Cluster

Bem-vindo ao cluster de IA da faculdade.
Este guia mostra como acessar, organizar seus arquivos e rodar experimentos de forma simples.

---

## 1. Visão geral

O cluster foi organizado para ficar fácil de usar:

- você entra na **máquina de login** por **Tailscale + SSH**
- pode abrir essa máquina no **VS Code Remote-SSH**
- prepara seu código e seu ambiente nela
- os treinos pesados vão para a **fila**
- os jobs podem rodar na **RTX A4000** ou na **GTX 1660**
- você acompanha tudo com logs em `~/logs`

### Comandos principais

```bash
run-a4000 python train.py --epochs 100
run-1660 python train.py --epochs 50
shell-a4000
myjobs
jobstatus 12345
joblog 12345
watchjob 12345
canceljob 12345
```

### O que cada comando faz

- `run-a4000`: envia seu experimento para a fila da GPU **RTX A4000**
- `run-1660`: envia seu experimento para a fila da GPU **GTX 1660**
- `shell-a4000`: abre uma sessão interativa na A4000 para testes e debug
- `myjobs`: mostra seus jobs atuais
- `jobstatus <jobid>`: mostra o status resumido de um job
- `joblog <jobid>`: acompanha o log de um job
- `watchjob <jobid>`: mostra status e log juntos, atualizando sozinho
- `canceljob <jobid>`: cancela um job

---

## 2. Regra de ouro

**Treino pesado sempre deve ser executado com `run-a4000`, `run-1660` ou `shell-a4000`.**

Você pode:

- acessar o cluster por SSH
- usar o VS Code remoto
- editar código
- usar Git
- criar e ativar seu ambiente Conda
- submeter experimentos para a fila

Você não deve:

- rodar treinamento pesado diretamente no terminal da máquina de login
- deixar processos pesados soltos fora da fila
- instalar pacotes globais no sistema
- depender do IP público do servidor para trabalhar de casa

---

## 3. Como acessar o cluster

O acesso oficial é feito por:

1. **Tailscale** no seu computador
2. **SSH** para o `cluster-login` usando o endereço do Tailscale

Você receberá do administrador:

- **usuário**
- **senha inicial**
- **nome ou IP Tailscale** do `cluster-login`

### Exemplo com IP do Tailscale

```bash
ssh seu_usuario@100.x.y.z
```

### Exemplo com nome do host

```bash
ssh seu_usuario@cluster-login
```

Na primeira conexão, confirme a chave digitando:

```text
yes
```

Depois informe sua senha.

---

## 4. Acesso pelo VS Code

O jeito mais confortável de trabalhar é com **VS Code Remote-SSH**.

### Passos

1. instale o **Visual Studio Code**
2. instale a extensão **Remote - SSH**
3. abra o arquivo `~/.ssh/config` do seu computador local
4. crie uma entrada para o cluster
5. conecte usando **Remote-SSH: Connect to Host**

### Exemplo de configuração SSH no seu computador

```ssh
Host cluster-faculdade
  HostName 100.x.y.z
  User seu_usuario
```

Depois, no VS Code, conecte em:

```text
cluster-faculdade
```

---

## 5. Estrutura recomendada de pastas

No seu diretório pessoal, use esta organização:

```text
~/projects/
~/datasets/
~/logs/
```

### Sugestão

- `~/projects/` → seus códigos e projetos
- `~/datasets/` → datasets e arquivos de entrada
- `~/logs/` → logs dos jobs

Exemplo:

```bash
mkdir -p ~/projects/meu_modelo
cd ~/projects/meu_modelo
```

---

## 6. Conda no cluster

O cluster usa uma instalação central do Conda em:

```text
/opt/miniconda3
```

Cada usuário cria seus **próprios ambientes** no home.

### Inicializando o Conda

Se o comando `conda` não estiver disponível no seu shell, rode:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
```

### Criando um ambiente

```bash
conda create -n meu_env python=3.10 -y
conda activate meu_env
```

### Conferindo o ambiente ativo

```bash
which python
python --version
echo "$CONDA_PREFIX"
```

### Instalação de pacotes

Prefira uma destas formas:

```bash
conda install tqdm -y
```

ou:

```bash
python -m pip install tqdm
```

### Observação importante

Evite usar `pip install ...` sem checar antes se o `pip` pertence ao seu ambiente ativo.
Se quiser confirmar:

```bash
which pip
python -m pip --version
```

---

## 7. Como os wrappers respeitam seu ambiente ativo

Os comandos `run-a4000` e `run-1660` foram preparados para tentar usar automaticamente o **ambiente Conda ativo no momento da submissão**.

Na prática, o fluxo esperado é:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
run-a4000 python train.py
```

### Regra prática

Antes de submeter um job, sempre faça:

```bash
conda activate meu_env
```

---

## 8. Rodando um experimento na A4000

Se você quer rodar um treino na GPU mais forte, use:

```bash
run-a4000 python train.py --epochs 100
```

### Exemplo completo

```bash
cd ~/projects/meu_modelo
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
run-a4000 python train.py --epochs 100 --batch-size 32
```

O sistema vai:

- enviar seu job para a fila da A4000
- retornar o ID do job
- salvar o log em `~/logs/`
- mostrar sugestões de acompanhamento, como `jobstatus`, `joblog` e `watchjob`

---

## 9. Rodando um experimento na GTX 1660

Se seu experimento é menor ou você quer usar a outra fila:

```bash
run-1660 python train.py --epochs 50
```

### Exemplo

```bash
cd ~/projects/meu_modelo
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
run-1660 python train.py --epochs 50 --batch-size 16
```

---

## 10. Acompanhando seus jobs

### Ver todos os seus jobs

```bash
myjobs
```

### Ver o status de um job específico

```bash
jobstatus 12345
```

### Ver o log de um job

```bash
joblog 12345
```

### Ver status e log juntos

```bash
watchjob 12345
```

### Estados comuns

- `PD` → pendente, aguardando recursos
- `R` → rodando
- `CG` → finalizando
- `CD` → concluído

### Dica prática

Para a maioria dos casos, o comando mais confortável é:

```bash
watchjob 12345
```

---

## 11. Cancelando um job

Se precisar cancelar:

```bash
canceljob 12345
```

Substitua `12345` pelo ID real do seu job.

---

## 12. Sessão interativa para debug

Se você quer testar algo interativamente na A4000, use:

```bash
shell-a4000
```

Depois, dentro da sessão:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
python
```

ou:

```bash
python debug.py
```

### Quando usar `shell-a4000`

Use para:

- debug rápido
- testes pequenos
- conferir GPU e ambiente
- rodar scripts curtos de validação

### Quando não usar

Não use uma sessão interativa para deixar treinos longos esquecidos.
Para treinos completos, prefira `run-a4000` ou `run-1660`.

---

## 13. Logs dos experimentos

Os logs ficam em:

```bash
~/logs/
```

Para listar:

```bash
ls ~/logs
```

Para acompanhar um log em tempo real:

```bash
tail -f ~/logs/slurm-12345.out
```

Mas, na prática, normalmente é mais fácil usar:

```bash
joblog 12345
```

ou:

```bash
watchjob 12345
```

---

## 14. Exemplo completo de fluxo de trabalho

### 1. Conectar ao Tailscale no seu computador

### 2. Entrar no cluster

```bash
ssh seu_usuario@100.x.y.z
```

### 3. Ir para o projeto

```bash
cd ~/projects/meu_modelo
```

### 4. Inicializar e ativar o ambiente

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
```

### 5. Enviar o treino

```bash
run-a4000 python train.py --epochs 100
```

### 6. Acompanhar

```bash
jobstatus 12345
watchjob 12345
```

---

## 15. Rodando treino longo sem medo de cair a conexão

Você pode começar o treino do seu computador de casa e ir embora. O treino continua no cluster.

### Melhor prática

Para treinos longos, prefira:

- `run-a4000`
- `run-1660`
- scripts submetidos pela fila

Quando o job entra no Slurm, ele continua rodando no cluster mesmo se você fechar o notebook.

---

## 16. Exemplo com script de treino

Se seu projeto usa um script bash, por exemplo `run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
python train.py --epochs 100
```

Você pode rodar:

```bash
run-a4000 bash run.sh
```

ou:

```bash
run-1660 bash run.sh
```

---

## 17. Conferindo GPU e PyTorch

Para verificar se a GPU está disponível:

```bash
python -c "import torch; print(torch.cuda.is_available())"
```

Para ver o nome da GPU:

```bash
python -c "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'sem gpu')"
```

Se quiser testar pela fila:

```bash
run-a4000 python -c "import torch; print(torch.cuda.is_available())"
```

---

## 18. Boas práticas

### Organização

- mantenha cada projeto em sua própria pasta
- não misture datasets com código
- salve checkpoints dentro do projeto
- limpe outputs antigos quando não forem mais necessários

### Ambientes

- use um ambiente Conda por projeto ou por família de projetos
- anote as dependências em `requirements.txt` ou `environment.yml`
- sempre ative o ambiente antes de chamar `run-a4000` ou `run-1660`

### Logs

- sempre confira o log se o job falhar
- use nomes claros para scripts e arquivos de saída
- prefira `joblog` ou `watchjob` em vez de decorar caminhos

### Recursos

- não envie jobs maiores do que precisa
- use a GTX 1660 para testes menores
- use a A4000 para treinos mais pesados

---

## 19. Problemas comuns

### 1. Não consigo acessar o cluster de casa

Confira:

- se o Tailscale do seu computador está conectado
- se você está usando o IP ou nome do Tailscale do servidor
- se o administrador confirmou que o `cluster-login` está online no Tailscale

### 2. `run-a4000: command not found`

O comando ainda não está disponível no seu ambiente de shell.
Entre em contato com o administrador.

### 3. `conda: command not found`

Inicialize o Conda:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
```

### 4. `python: command not found` no log do job

Isso normalmente significa que o job foi submetido sem ambiente ativo.
Faça:

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
```

E submeta novamente.

### 5. `ModuleNotFoundError`

O pacote não está instalado no ambiente ativo.
Tente:

```bash
conda install nome_do_pacote -y
```

ou:

```bash
python -m pip install nome_do_pacote
```

### 6. O job ficou pendente

Isso normalmente significa que:

- a GPU está ocupada
- não há memória suficiente disponível
- há outro job na frente da fila

Use:

```bash
myjobs
```

ou:

```bash
jobstatus 12345
```

E aguarde a liberação dos recursos.

### 7. O treinamento falhou logo no começo

Veja o log:

```bash
joblog 12345
```

ou:

```bash
tail -n 50 ~/logs/slurm-12345.out
```

---

## 20. Resumo rápido

### Conectar ao cluster

```bash
ssh seu_usuario@100.x.y.z
```

### Inicializar e ativar ambiente

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
source /etc/profile.d/conda-user-dirs.sh
conda activate meu_env
```

### Rodar na A4000

```bash
run-a4000 python train.py --epochs 100
```

### Rodar na 1660

```bash
run-1660 python train.py --epochs 50
```

### Acompanhar

```bash
myjobs
jobstatus 12345
joblog 12345
watchjob 12345
```

### Cancelar

```bash
canceljob 12345
```

### Sessão interativa

```bash
shell-a4000
```

---

## 21. Quando pedir ajuda

Procure o administrador se:

- seu acesso por Tailscale ou SSH não funcionar
- o VS Code não conectar
- os comandos `run-a4000` ou `run-1660` não existirem
- o Conda não estiver disponível mesmo após `source`
- sua pasta pessoal não aparecer corretamente
- sua GPU parecer indisponível mesmo com fila livre

---

Bom trabalho e bons experimentos.
