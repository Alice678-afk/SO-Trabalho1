# SO-Trabalho1

## Grupo

| Nome | Número mecanográfico |
|------|----------------------|
| Adriana Martins | 132842 |
| Alice Tembe     | 134713 |

O `vp` (Vigia-Pirata) é um programa que permite detetar alterações nos ficheiros de um ou mais diretórios, podendo identificar situações como modificações ou eliminações de ficheiros.

No modo de proteção, o programa cria uma base de dados com a informação original dos ficheiros. No modo de verificação, compara o estado atual dos ficheiros com os dados guardados, identificando ficheiros novos, apagados ou modificados.

## Requisitos

- Linux
- Bash 4 ou superior (o `vp` usa arrays associativos)
- Comandos usados: `find`, `stat`, `sha256sum`, `grep`, `awk` e `logger`
- Opcional: `journalctl`, para consultar os alertas enviados com a opção `-s`

## Instalação

O `vp` é um único ficheiro (`vp.sh`), não precisa de mais nada.

1. Copiar o ficheiro `vp.sh` para o computador.
2. Dar permissão de execução:

```
chmod +x vp.sh
```

## Início rápido

```
./vp.sh -p <diretório> -f minha_bd      # protege um diretório
./vp.sh -v -f minha_bd                  # verifica alterações
```

## Como correr o projeto

### Sintaxe

```
./vp.sh [-p <dir1> [<dir2>...] | -v] [-f <ficheiro>] [-e <padrao>] [-s]
```

### Opções

| Opção | O que faz |
|-------|-----------|
| `-p <dir1> [<dir2>...]` | Modo de proteção: cria a base de dados com a informação de todos os ficheiros dos diretórios e subdiretórios (dono, grupo, tamanho, permissões, data de modificação e SHA-256) e guarda também os diretórios protegidos. |
| `-v` | Modo de verificação: compara o estado atual dos ficheiros com a base de dados e reporta as diferenças. |
| `-f <ficheiro>` | Indica o ficheiro da base de dados, tanto para criar como para verificar. |
| `-e <padrao>` | Exclui da proteção e da verificação os ficheiros cujo caminho combina com o padrão (por exemplo `"*.log"`). O padrão deve ir entre aspas. |
| `-s` | Envia os alertas (apagados, modificados e novos) para o sistema de logging, através do `logger`, com a etiqueta `vp`. |

Notas:
- As opções `-p` e `-v` não podem ser usadas em simultâneo.
- As opções podem vir antes ou depois dos diretórios.

### Valores por defeito

- **Base de dados:** `/tmp/.pdb`
- **Modo:** verificação (se não for indicado `-p` nem `-v`)

### A base de dados é só de leitura

Depois de criada com `-p`, a base de dados fica com permissões `444` (só de leitura), para dificultar alterações acidentais. Para a criar de novo, basta voltar a correr `./vp.sh -p ...`: o `vp` apaga a base de dados antiga antes de gerar a nova.

Esta proteção não impede um utilizador `root` de a alterar.

## Exemplos

Os exemplos usam uma pasta `projeto` com três ficheiros: `notas.txt`, `dados.txt` e `app.log`.

### Proteger diretórios

```
$ ./vp.sh -p projeto -f bd
Base de dados de proteção bd foi criada com sucesso.
Ficheiros processados: 3
Diretórios protegidos: projeto
```

### Verificar alterações

Sem alterações desde a proteção:

```
$ ./vp.sh -v -f bd
Resumo da Verificação: 3 verificados | 0 Modificados | 0 Apagados | 0 Novos
```

### Ignorar ficheiros com -e

Proteger ignorando os ficheiros `.log`:

```
$ ./vp.sh -p projeto -f bd_e -e "*.log"
Base de dados de proteção bd_e foi criada com sucesso.
Ficheiros processados: 2
Diretórios protegidos: projeto
```

Depois de criar um `novo.txt` e um `novo.log`, só o `novo.txt` é reportado, porque o padrão também é aplicado na verificação:

```
$ ./vp.sh -v -f bd_e
projeto/novo.txt é NOVO
  Informação atual: USER=root, GROUP=root, SIZE=2, PERM=644, SHA256=a4fb6214...
Resumo da Verificação: 2 verificados | 0 Modificados | 0 Apagados | 1 Novos
```

## O que o vp deteta

| Alteração | Como é reportada |
|-----------|------------------|
| Ficheiro novo | `NOVO` |
| Ficheiro apagado | `APAGADO` |
| Alteração da posse (dono ou grupo) | `MODIFICADO (... Posse)` |
| Modificação do tamanho | `MODIFICADO (... Tamanho)` |
| Modificação do conteúdo (SHA-256) | `MODIFICADO (... Conteúdo)` |
| Alteração das permissões | `MODIFICADO (... Permissões)` |
| Alteração da data de modificação | `MODIFICADO (... Data)` |

## Como ler os resultados

Exemplo, depois de acrescentar texto ao `notas.txt`, apagar o `dados.txt` e criar um `novo.txt`:

```
$ ./vp.sh -v -f bd
projeto/dados.txt foi APAGADO
  Informação inicial: USER=root, GROUP=root, SIZE=2, PERM=644, SHA256=02638299...
  Informação atual: [Ficheiro não encontrado no sistema]
projeto/notas.txt foi MODIFICADO (Alteração de: Conteúdo Tamanho Data)
  Informação inicial: USER=root, GROUP=root, SIZE=2, PERM=644, SHA256=87428fc5...
  Informação atual: USER=root, GROUP=root, SIZE=7, PERM=644, SHA256=5d6165ee...
projeto/novo.txt é NOVO
  Informação atual: USER=root, GROUP=root, SIZE=2, PERM=644, SHA256=a4fb6214...
Resumo da Verificação: 3 verificados | 1 Modificados | 1 Apagados | 1 Novos
```

- Cada ficheiro com problemas tem uma linha a dizer o que lhe aconteceu.
- Nos apagados e modificados aparece a **informação inicial** (a que estava na base de dados). Nos modificados aparece também a **informação atual**, para comparar. Nos novos só existe informação atual.
- A última linha resume a verificação. Os ficheiros novos não contam para o número de verificados, porque não estavam na base de dados.

## Formato da base de dados

É um ficheiro de texto com três tipos de linhas:

```
#DIR <diretório protegido>        (uma linha por diretório)
#EXCLUIR <padrão>                 (o padrão do -e, ou vazio)
caminho|user|grupo|tamanho|permissões|data|sha256     (uma linha por ficheiro)
```

## Erros comuns

Em todos estes casos o `vp` escreve uma mensagem de erro, mostra a ajuda de uso e termina.

| Situação | Como resolver |
|----------|---------------|
| `Opção inválida: -x`, ou `-f` / `-e` sem o valor | Usar só as opções `-p`, `-v`, `-f`, `-e` e `-s`, e dar um valor ao `-f` e ao `-e`. |
| `Erro: não podes usar -p e -v ao mesmo tempo` | Escolher só um dos modos. |
| `Erro: o -p precisa de pelo menos um diretório` | Indicar pelo menos um diretório a seguir ao `-p`. |
| `Erro: '<x>' não é um diretório` | Verificar o caminho indicado: tem de ser um diretório que exista. |
| `Erro: base de dados '<ficheiro>' não encontrada` | Criar primeiro a base de dados com `-p`, ou indicar com `-f` o ficheiro certo. |

## Resolução de problemas

| Problema | Solução |
|----------|---------|
| `Permission denied` ao correr `./vp.sh` | Dar permissão de execução: `chmod +x vp.sh` |
| Todos os ficheiros aparecem como `APAGADO` | O diretório protegido mudou de sítio ou foi apagado |
| `Permission denied` ao escrever a base de dados | O ficheiro da base de dados está noutra pasta onde não há permissão de escrita: escolher outro caminho com `-f` |

## Estrutura da entrega

```
entrega/
├── vp.sh                    programa (criação da base de dados + interface e verificação)
├── README.md                este ficheiro
├── Relatório.pdf            relatório do trabalho
├── Declaração de IA.pdf     declaração de utilização de IA
├── TrabalhoPratico1.pptx    slides da apresentação oral
└── TrabalhoPratico1.pdf     slides da apresentação oral (PDF)
```

No ficheiro `vp.sh`, a parte da criação da base de dados (função `gerar_base_dados`) está identificada com o comentário `PARTE ALICE`, e a interface e a verificação com `PARTE ADRIANA`. A ajuda do programa (`Uso: ./vp ...`) usa o nome `vp`, que é o nome do comando no enunciado.
