#!/bin/bash
while getopts "pvf:" opcao; do
    case $opcao in
        p) echo "Escolheste -p" ;;
        v) echo "Escolheste -v" ;;
        f) echo "Ficheiro: $OPTARG" ;;
        *) echo "Opção inválida" ;;
    esac
done
