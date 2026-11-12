# SO-Trabalho1

## Demonstração

## Guarda o código num ficheiro chamado vp.sh e dá-lhe permissão para ser executado:

```
chmod +x vp.sh
```

## Proteger um Diretório

### Criar uma pasta de teste e ficheiros

```
mkdir -p meu_projeto
echo "texto original" > meu_projeto/notas.txt
```

### Proteger a pasta com o vp

```
./vp.sh -p meu_projeto -f minha_bd
```

# Alterar um Ficheiro

### Mudar o conteúdo do ficheiro

```
echo "texto alterado e novo" >> meu_projeto/notas.txt
```

### Criar um ficheiro novo ou apagar algo para testar mais deteções

```
echo "outro ficheiro" > meu_projeto/novo.txt
rm meu_projeto/notas.txt # (ou podes só alterar o texto acima)
```

# Verificar Alterações

```
./vp.sh -v -f minha_bd
```
