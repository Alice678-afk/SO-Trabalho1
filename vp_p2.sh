#!/bin/bash

# Valores por defeito (definidos ANTES de ler as opções)
modo=""
ficheiro_bd="/tmp/.pdb"
usar_logger=0

# Ler as opções: p, v e s são interruptores; f recebe um valor (por isso o ":")
while getopts "pvf:s" opcao; do
    case $opcao in
        p) modo="p" ;;
        v) modo="v" ;;
        f) ficheiro_bd="$OPTARG" ;;
        s) usar_logger=1 ;;
        *) echo "Opção inválida" ;;
    esac
done

# Só para testar (depois removes)
echo "modo=$modo bd=$ficheiro_bd logger=$usar_logger"
