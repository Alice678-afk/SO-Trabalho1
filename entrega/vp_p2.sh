#!/bin/bash

# PARTE ALICE: CRIAÇÃO DA BASE DE DADOS

# Cria a base de dados, guardando os diretórios protegidos e a informação
gerar_base_dados() {
    local ficheiro_bd="$1"
    local padrao_exclusao="$2"

    shift 2

    [ $# -eq 0 ] && return 1

    > "$ficheiro_bd"

    # Guarda os diretórios e o padrão de exclusão nos metadados da BD
    for dir in "$@"; do
        echo "#DIR $dir" >> "$ficheiro_bd"
    done

    echo "#EXCLUIR $padrao_exclusao" >> "$ficheiro_bd"

    # Percorre os diretórios e regista os dados de cada ficheiro encontrado
    for dir in "$@"; do

        [[ ! -d "$dir" ]] && continue

        while IFS= read -r -d '' ficheiro; do

            [[ ! -f "$ficheiro" ]] && continue
            [[ "$ficheiro" -ef "$ficheiro_bd" ]] && continue

            if [[ -n "$padrao_exclusao" ]]; then
                [[ "$ficheiro" == $padrao_exclusao ]] && continue
            fi

            local caminho="$ficheiro"
            local user=$(stat -c '%U' -- "$ficheiro" 2>/dev/null)
            local grupo=$(stat -c '%G' -- "$ficheiro" 2>/dev/null)
            local tamanho=$(stat -c '%s' -- "$ficheiro" 2>/dev/null)
            local permissoes=$(stat -c '%a' -- "$ficheiro" 2>/dev/null)
            local data=$(stat -c '%Y' -- "$ficheiro" 2>/dev/null)
            local sha256=$(sha256sum -- "$ficheiro" 2>/dev/null | awk '{print $1}')

            echo "$caminho|$user|$grupo|$tamanho|$permissoes|$data|$sha256" >> "$ficheiro_bd"

        done < <(find "$dir" -type f -print0)

    done
}


# PARTE ADRIANA: INTERFACE E VERIFICAÇÃO

# Inicializa as variáveis utilizadas pelo programa
modo=""
ficheiro_bd="/tmp/.pdb"
usar_logger=0

# Apresenta as opções disponíveis quando ocorre um erro na utilização
uso() {
    echo "Uso: ./vp [-p <dir1> [<dir2>...]] [-v] [-f <ficheiro>] [-e <padrao>] [-s]"
    echo "    -p : Protege um ou mais diretórios"
    echo "    -v : Verifica alterações nos ficheiros protegidos"
    echo "    -f : Indica o ficheiro onde a base de dados será guardada"
    echo "    -e : Exclui ficheiros que correspondam ao padrão indicado"
    echo "    -s : Envia alertas para o sistema de logging usando logger"
    exit 1
}

# Envia alertas para o sistema de logging quando a opção -s está ativa
alerta() {
    if [[ $usar_logger == 1 ]]; then
        logger -t vp -p user.warning "$1"
    fi
}

flag_p=0
flag_v=0
dirs_protegidos=()
padrao_excluir=""

# Percorre os argumentos recebidos
while [[ $# -gt 0 ]]; do

    case "$1" in

        -p)
            modo="p"
            flag_p=1
            shift
            ;;

        -v)
            modo="v"
            flag_v=1
            shift
            ;;

        -f)
            [[ $# -lt 2 ]] && uso
            ficheiro_bd="$2"
            shift 2
            ;;

        -e)
            [[ $# -lt 2 ]] && uso
            padrao_excluir="$2"
            shift 2
            ;;

        -s)
            usar_logger=1
            shift
            ;;

        --)
            shift
            while [[ $# -gt 0 ]]; do
                dirs_protegidos+=("$1")
                shift
            done
            ;;

        -*)
            echo "Opção inválida: $1" >&2
            uso
            ;;

        *)
            dirs_protegidos+=("$1")
            shift
            ;;

    esac
done


# Impede a utilização simultânea dos modos de proteção e verificação
if [[ $flag_p == 1 && $flag_v == 1 ]]; then
    echo "Erro: não podes usar -p e -v ao mesmo tempo" >&2
    uso
fi

# Verifica se foi indicado pelo menos um diretório no modo de proteção
if [[ $flag_p == 1 && ${#dirs_protegidos[@]} -eq 0 ]]; then
    echo "Erro: o -p precisa de pelo menos um diretório" >&2
    uso
fi

# Define a verificação como modo de execução por defeito
if [[ -z "$modo" ]]; then
    modo="v"
fi

# Confirma a existência da base de dados antes de iniciar a verificação
if [[ $modo == "v" && ! -f "$ficheiro_bd" ]]; then
    echo "Erro: base de dados '$ficheiro_bd' não encontrada" >&2
    uso
fi

# Valida todos os diretórios indicados antes de iniciar a proteção
if [[ $modo == "p" ]]; then

    for d in "${dirs_protegidos[@]}"; do
        if [[ ! -d "$d" ]]; then
            echo "Erro: '$d' não é um diretório" >&2
            uso
        fi
    done

    # Cria uma nova base de dados com os diretórios e exclusões 
    rm -f "$ficheiro_bd"

    gerar_base_dados "$ficheiro_bd" "$padrao_excluir" "${dirs_protegidos[@]}"

    chmod 444 "$ficheiro_bd"

    n_ficheiros=$(grep -vc '^#' "$ficheiro_bd")

    echo "Base de dados de proteção $ficheiro_bd foi criada com sucesso."
    echo "Ficheiros processados: $n_ficheiros"
    echo "Diretórios protegidos: ${dirs_protegidos[*]}"

fi

apagados=0
modificados=0
verificados=0
novos=0


# Percorre a base de dados e compara a informação inicial de cada ficheiro com a informação atual
if [[ $modo == "v" ]]; then

    declare -A registados=()

    while IFS= read -r linha; do

        # Ignora os metadados e processa apenas os registos dos ficheiros
        [[ "$linha" == "#"* ]] && continue

        IFS='|' read -r caminho user grupo tamanho permissoes data sha256 <<< "$linha"

        [[ -z "$caminho" ]] && continue

        registados["$caminho"]=1

        verificados=$((verificados + 1))

        # Identifica os ficheiros que foram apagados desde a criação da BD
        if [[ ! -f "$caminho" ]]; then

            echo "$caminho foi APAGADO"
            alerta "$caminho foi APAGADO"

            echo "  Informação inicial: USER=$user, GROUP=$grupo, SIZE=$tamanho, PERM=$permissoes, SHA256=$sha256"
            echo "  Informação atual: [Ficheiro não encontrado no sistema]"

            apagados=$((apagados + 1))

        else

            # Recolhe novamente os metadados para comparar com os valores iniciais
            sha256_atual=$(sha256sum -- "$caminho" | awk '{print $1}')
            user_atual=$(stat -c %U -- "$caminho")
            grupo_atual=$(stat -c %G -- "$caminho")
            tamanho_atual=$(stat -c %s -- "$caminho")
            perm_atual=$(stat -c %a -- "$caminho")
            data_atual=$(stat -c %Y -- "$caminho")

            alteracoes=""

            # Compara o conteúdo do ficheiro
            if [[ "$sha256_atual" != "$sha256" ]]; then
                alteracoes="$alteracoes Conteúdo"
            fi

            # Compara o tamanho atual com o tamanho inicial
            if [[ "$tamanho" != "$tamanho_atual" ]]; then
                alteracoes="$alteracoes Tamanho"
            fi

            # Verifica se as permissões do ficheiro foram alteradas
            if [[ "$permissoes" != "$perm_atual" ]]; then
                alteracoes="$alteracoes Permissões"
            fi

            # Compara as datas de modificação do ficheiro
            if [[ "$data" != "$data_atual" ]]; then
                alteracoes="$alteracoes Data"
            fi

            # Verifica se o utilizador ou o grupo proprietário foram alterados
            if [[ "$user" != "$user_atual" || "$grupo" != "$grupo_atual" ]]; then
                alteracoes="$alteracoes Posse"
            fi

            # Apresenta os ficheiros modificados e as respetivas diferenças
            if [[ -n "$alteracoes" ]]; then

                echo "$caminho foi MODIFICADO (Alteração de:$alteracoes)"
                alerta "$caminho foi MODIFICADO (Alteração de:$alteracoes)"

                modificados=$((modificados + 1))

                echo "  Informação inicial: USER=$user, GROUP=$grupo, SIZE=$tamanho, PERM=$permissoes, SHA256=$sha256"
                echo "  Informação atual: USER=$user_atual, GROUP=$grupo_atual, SIZE=$tamanho_atual, PERM=$perm_atual, SHA256=$sha256_atual"

            fi

        fi

    done < "$ficheiro_bd"


    # Recupera os diretórios protegidos e o padrão de exclusão guardados
    dirs_protegidos=()
    padrao=""

    while IFS= read -r linha; do

        case "$linha" in
            "#DIR "*)
                dirs_protegidos+=("${linha#\#DIR }")
                ;;
            "#EXCLUIR "*)
                padrao="${linha#\#EXCLUIR }"
                ;;
        esac

    done < "$ficheiro_bd"


    # Percorre novamente os diretórios protegidos para identificar ficheiros que não estavam na BD anteriormente
    for dir in "${dirs_protegidos[@]}"; do

        while IFS= read -r -d '' ficheiro; do

            [[ ! -f "$ficheiro" ]] && continue
            [[ "$ficheiro" -ef "$ficheiro_bd" ]] && continue

            # Ignora os ficheiros que correspondem ao padrão de exclusão
            if [[ -n "$padrao" && "$ficheiro" == $padrao ]]; then
                continue
            fi

            # Verifica se o ficheiro já estava registado na base de dados
            if [[ -z ${registados["$ficheiro"]+x} ]]; then

                echo "$ficheiro é NOVO"
                alerta "$ficheiro é NOVO"

                # Recolhe os dados atuais dos ficheiros novos encontrados
                sha256_atual=$(sha256sum -- "$ficheiro" | awk '{print $1}')
                user_atual=$(stat -c %U -- "$ficheiro")
                grupo_atual=$(stat -c %G -- "$ficheiro")
                tamanho_atual=$(stat -c %s -- "$ficheiro")
                perm_atual=$(stat -c %a -- "$ficheiro")

                echo "  Informação atual: USER=$user_atual, GROUP=$grupo_atual, SIZE=$tamanho_atual, PERM=$perm_atual, SHA256=$sha256_atual"

                novos=$((novos + 1))

                # Regista o caminho para evitar contagens duplicadas
                registados["$ficheiro"]=1

            fi

        done < <(find "$dir" -type f -print0)

    done


    # Apresenta o resumo final
    echo "Resumo da Verificação: $verificados verificados | $modificados Modificados | $apagados Apagados | $novos Novos"

fi

