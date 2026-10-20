# SO-Trabalho1

O `vp` (vigia-pirata) deteta se os ficheiros de um ou mais diretórios foram alterados, por exemplo por uma intrusão. No modo de proteção guarda uma base de dados com a informação original dos ficheiros, e no modo de verificação compara o estado atual com essa base de dados.

## Grupo

| Nome | Número mecanográfico |
|------|----------------------|
| Adriana Martins | 132842 |
| Alice Tembe |  |

## Requisitos

- Linux
- Bash
- Comandos usados: `find`, `stat`, `sha256sum`, `grep`, `awk`, `cut` e `logger`
- Opcional: `journalctl`, para consultar os alertas enviados com a opção `-s`

## Instalação

1. Copiar os ficheiros do repositório para o computador, por exemplo, com `git clone`.
2. Garantir que o `vp` e o `parte_a.sh` estão **na mesma pasta**, porque o `vp` carrega as funções do `parte_a.sh`.
3. Dar permissão de execução ao `vp`:

```
chmod +x vp
```

## Como correr o projeto

### Sintaxe

```
./vp [-p <dir1> [<dir2>...] | -v] [-f <ficheiro>] [-e <padrao>] [-s]
```

### Opções

| Opção | O que faz |
|-------|-----------|
| `-p <dir1> [<dir2>...]` | Modo de proteção, cria a base de dados com a informação de todos os ficheiros dos diretórios e subdiretórios (dono, grupo, tamanho, permissões, data de modificação e SHA-256) e guarda também os diretórios protegidos. |
| `-v` | Modo de verificação, compara o estado atual dos ficheiros com a base de dados e reporta as diferenças. |
| `-f <ficheiro>` | Indica o ficheiro da base de dados, tanto para criar como para verificar. |
| `-e <padrao>` | Exclui da proteção e da verificação os ficheiros cujo caminho combina com o padrão (por exemplo `"*.log"`), o padrão deve ir entre aspas. |
| `-s` | Envia os alertas (apagados, modificados e novos) para o sistema de logging, através do `logger`, com a etiqueta `vp`. |

Notas:
- As opções `-p` e `-v` não podem ser usadas em simultâneo.
- As opções podem vir antes ou depois dos diretórios.

### Valores por defeito

- **Base de dados:** `/tmp/.pdb`
- **Modo:** verificação (se não for indicado `-p` nem `-v`)

## Exemplos

### Proteger diretórios

```
$ ./vp -p /tmp/amb -f bd_final
Base de dados de proteção bd_final foi criada com sucesso.
Ficheiros processados: 7
Diretórios protegidas:  /tmp/amb
```

### Verificar alterações

Sem alterações desde a proteção:

```
$ ./vp -v -f bd_final
Resumo da Verificação: 7 verificados | 0 Modificados | 0 Apagados | 0 Novos
```

### Ignorar ficheiros com -e

Proteger ignorando os ficheiros `.log`:

```
$ ./vp -p /tmp/amb -f bd_e -e "*.log"
Base de dados de proteção bd_e foi criada com sucesso.
Ficheiros processados: 3
Diretórios protegidas:  /tmp/amb
```

Depois de criar um ficheiro `d.txt` e um `e.log`, só o `d.txt` é reportado, porque o padrão também é aplicado na verificação:

```
$ ./vp -v -f bd_e
/tmp/amb/d.txt é NOVO
Resumo da Verificação: 3 verificados | 0 Modificados | 0 Apagados | 1 Novos
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

Exemplo com três alterações:

```
/tmp/amb/f2.txt foi APAGADO
  Informação inicial: USER=adrianamoranguita, GROUP=adrianamoranguita, SIZE=2, PERM=664, SHA256=3bb2abb6...
/tmp/amb/f1.txt foi MODIFICADO (Alteração de: Conteúdo Tamanho Data)
  Informação inicial: USER=adrianamoranguita, GROUP=adrianamoranguita, SIZE=2, PERM=664, SHA256=73cb3858...
  Informação atual: USER=adrianamoranguita, GROUP=adrianamoranguita, SIZE=7, PERM=664, SHA256=cb9d5846...
/tmp/amb/f3.txt é NOVO
Resumo da Verificação: 2 verificados | 1 Modificados | 1 Apagados | 1 Novos
```

- Cada ficheiro com problemas tem uma linha a dizer o que lhe aconteceu.
- Nos apagados e modificados aparece a **informação inicial** (a que estava na base de dados). Nos modificados aparece também a **informação atual**, para comparar.
- A última linha resume a verificação. Os ficheiros novos não contam para o número de verificados, porque não estavam na base de dados.

## Erros comuns

Em todos estes casos o `vp` escreve uma mensagem de erro, mostra a ajuda de uso e termina.

| Situação | Como resolver |
|----------|---------------|
| Opção inválida (por exemplo `-x`), ou opção que precisa de valor sem o valor (`-f` sozinho) | Usar só as opções `-p`, `-v`, `-f`, `-e` e `-s`, e dar um valor ao `-f` e ao `-e`. |
| `Erro: não podes usar -p e -v ao mesmo tempo` | Escolher só um dos modos. |
| `Erro: o -p precisa de pelo menos um diretório` | Indicar pelo menos um diretório a seguir ao `-p`. |
| `Erro: base de dados '<ficheiro>' não encontrada` | Criar primeiro a base de dados com `-p`, ou indicar com `-f` o ficheiro certo. |

## Estrutura do repositório

```
SO-Trabalho1/
├── README.md
├── ParteA/
│   ├── parte_a.sh      função que cria a base de dados (modo -p)
│   ├── testar.sh       script de teste dessa função
│   └── exemplo_bd.txt  exemplo de base de dados
└── ParteB/
    ├── vp_p2.sh        interface e verificação (modo -v)
    ├── parte_a.sh      cópia da função da ParteA
    └── testes_p2.txt   testes realizados
```
