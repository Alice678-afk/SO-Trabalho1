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

alerta() {
  if [[ $usar_logger == 1 ]]; then
    logger -t vp -p user.warning "$1"
  fi
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

if [[ -z $modo ]]; then
    modo="v"
fi

if [[ $modo == "v" && ! -f "$ficheiro_bd" ]]; then
    echo "Erro: base de dados '$ficheiro_bd' não encontrada" >&2
    uso
fi

apagados=0
modificados=0
verificados=0
novos=0

if [[ $modo == "v" ]]; then
 while IFS='|' read -r caminho user grupo tamanho permissoes data sha256; do
  
    if [[ "$caminho" == "#"* ]]; then
    continue
  fi
  
  verificados=$((verificados + 1))
  if [[ ! -e "$caminho" ]]; then
  
     echo "$caminho foi APAGADO"
     alerta "$caminho foi APAGADO"
     
     echo "  Informação inicial: USER=$user, GROUP=$grupo, SIZE=$tamanho, PERM=$permissoes, SHA256=$sha256"
     apagados=$((apagados + 1))
  
  else 
   sha256_atual=$(sha256sum "$caminho" | awk '{print $1}')
   user_atual=$(stat -c %U "$caminho")
   grupo_atual=$(stat -c %G "$caminho")
   tamanho_atual=$(stat -c %s "$caminho")
   perm_atual=$(stat -c %a "$caminho")
   data_atual=$(stat -c %Y "$caminho")
   
   alteracoes=""
   
   if [[ "$sha256_atual" != "$sha256" ]]; then
    alteracoes="$alteracoes Conteúdo"
   fi

   if [[ "$tamanho" != "$tamanho_atual" ]]; then
    alteracoes="$alteracoes Tamanho"
   fi
   
   if [[ "$permissoes" != "$perm_atual" ]]; then
    alteracoes="$alteracoes Permissões"
   fi
   
   if [[ "$data" != "$data_atual" ]]; then
    alteracoes="$alteracoes Data"
   fi
   
   if [[ "$user" != "$user_atual" || "$grupo" != "$grupo_atual" ]]; then
    alteracoes="$alteracoes Posse"
   fi
     
   if [[ -n "$alteracoes" ]]; then
    echo "$caminho foi MODIFICADO (Alteração de:$alteracoes)"
    alerta "$caminho foi MODIFICADO (Alteração de:$alteracoes)"
    
    modificados=$((modificados + 1))
    
    echo "  Informação inicial: USER=$user, GROUP=$grupo, SIZE=$tamanho, PERM=$permissoes, SHA256=$sha256"
    echo "  Informação atual: USER=$user_atual, GROUP=$grupo_atual,   SIZE=$tamanho_atual, PERM=$perm_atual, SHA256=$sha256_atual"
    
   fi
   
  fi
 done < "$ficheiro_bd"
 
  dir_teste="/tmp/amb"

 while IFS= read -r ficheiro; do
  if ! grep -q -F "$ficheiro|" "$ficheiro_bd"; then
   echo "$ficheiro é NOVO"
   alerta "$ficheiro é NOVO"
   novos=$((novos + 1))
  fi
 done < <(find "$dir_teste" -type f)
 
 echo "Resumo da Verificação: $verificados verificados | $modificados Modificados | $apagados Apagados | $novos Novos"
 
 
fi
	

# Só para testar
echo "modo=$modo bd=$ficheiro_bd logger=$usar_logger"
