#!/bin/bash

source "./parte_a.sh"

DIRETORIO_TESTE="/tmp/ambiente_teste"
BD_TESTE="/tmp/base_dados_teste.txt"

mkdir -p "$DIRETORIO_TESTE"
echo "Texto do primeiro ficheiro" > "$DIRETORIO_TESTE/ficheiro1.txt"
echo "Texto do segundo ficheiro" > "$DIRETORIO_TESTE/ficheiro2.txt"

echo "testar a geração da base de dados"

gerar_base_dados "$BD_TESTE" "$DIRETORIO_TESTE"

cat "$BD_TESTE"

rm -rf "$DIRETORIO_TESTE"
rm -f "$BD_TESTE"
