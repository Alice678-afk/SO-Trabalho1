#!/bin/bash

gerar_base_dados() {
    local ficheiro_bd="$1"
    #adicionar o padrão e
    local padrao_exclusao="$2" 
    
    shift 2

    [ $# -eq 0 ] && return 1

    > "$ficheiro_bd"
    
    #adicionar os diretórios protegidos
    echo "$@" >> "$ficheiro_bd"
    echo "$padrao_exclusao" >> "$ficheiro_bd"
    

    for dir in "$@"; do
        [[ ! -d "$dir" ]] && continue

        while IFS= read -r ficheiro; do
            [[ ! -f "$ficheiro" ]] && continue
            
            if [[ -n "$padrao_exclusao" ]]; then
                [[ "$ficheiro" == $padrao_exclusao ]] && continue
            fi
            
            local caminho="$ficheiro"
            local user=$(stat -c '%U' "$ficheiro" 2>/dev/null)
            local grupo=$(stat -c '%G' "$ficheiro" 2>/dev/null)
            local tamanho=$(stat -c '%s' "$ficheiro" 2>/dev/null)
            local permissoes=$(stat -c '%a' "$ficheiro" 2>/dev/null)
            local data=$(stat -c '%Y' "$ficheiro" 2>/dev/null)
            local sha256=$(sha256sum "$ficheiro" 2>/dev/null | awk '{print $1}')

            echo "$caminho|$user|$grupo|$tamanho|$permissoes|$data|$sha256" >> "$ficheiro_bd"

        done < <(find "$dir" -type f)
    done
}
