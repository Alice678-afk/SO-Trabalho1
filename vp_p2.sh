#!/bin/bash

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

flag_p=0
flag_v=0

while getopts "pvf:s" opcao; do
    case $opcao in
        p) modo="p"
           flag_p=1 ;;
        v) modo="v"
           flag_v=1 ;;
        f) ficheiro_bd="$OPTARG" ;;
        s) usar_logger=1 ;;
        *) echo "Opção inválida" >&2
           uso ;;
    esac
done

if [[ $flag_p == 1 && $flag_v == 1 ]]; then
   echo "Erro: não podes usar -p e -v ao mesmo tempo" >&2
   uso
fi

if [[ -z $modo && ! -f "$ficheiro_bd" ]]; then

   modo="v"
   echo "Erro: base de dados '$ficheiro_bd' não encontrada" >&2
   uso
fi

apagados=0

if [[ $modo == "v" ]]; then
 while IFS='|' read -r caminho user grupo tamanho permissoes data sha256; do
  if [[ ! -e "$caminho" ]]; then
     echo "$caminho foi APAGADO"
     echo "  Informação inicial: USER=$user, GROUP=$grupo, SIZE=$tamanho, PERM=$permissoes, SHA256=$sha256"
     apagados=$((apagados + 1))
  fi
 done < "$ficheiro_bd"
 echo "Apagados: $apagados"
 
fi

# Só para testar
echo "modo=$modo bd=$ficheiro_bd logger=$usar_logger"
