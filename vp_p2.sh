#!/bin/bash

# Valores por defeito (definidos ANTES de ler as opções)
modo=""
ficheiro_bd="/tmp/.pdb"
usar_logger=0

#função para aparecer mensagem a ajudar o utilizador quando da erro
uso() {
    echo "Uso: ./vp [{-p <dir1> [<dir2>...] | -v}] [-f <ficheiro>] [-e <padrao>] [-s]"
    echo "    -p : Protege e guarda informação acerca de um ou mais diretórios"
    echo "    -v : Verifica alterações em ficheiros desde que foram protegidos"
    echo "    -f : Indicação do nome do ficheiro onde a base de dados será guardada (Por defeito será tmp/.pdb)"
    echo "    -e : Permite a exclusão de ficheiros voláteis (ex. *.tmp, *.log,
 /tmp/*) da proteção e verificação"
    echo "    -s : Emissão de alertas de alta prioridade para o sistema de logging
 usando o logger"
    exit 1
}


while getopts "pvf:s" opcao; do
    case $opcao in
        p) modo="p" ;;
        v) modo="v" ;;
        f) ficheiro_bd="$OPTARG" ;;
        s) usar_logger=1 ;;
        *) echo "Opção inválida" >&2
           uso ;;
    esac
done

# Só para testar (depois removes)
echo "modo=$modo bd=$ficheiro_bd logger=$usar_logger"
