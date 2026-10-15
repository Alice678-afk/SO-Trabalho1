#!/bin/bash

gerar_base_dados() {
    local ficheiro_bd="$1"
    shift

    [ $# -eq 0 ] && return 1

    > "$ficheiro_bd"

    for dir in "$@"; do
        [[ ! -d "$dir" ]] && continue

        while IFS= read -r ficheiro; do
            [[ ! -f "$ficheiro" ]] && continue

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
