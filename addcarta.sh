#!/bin/bash
# Fecha se algum comando falhar
set -e

# Available colors
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

function selectQuery(){
  tabela=$1
  ultimoElemento=$2

  psql -U postgres -d mtg -c "select nome as ${tabela^} from ${tabela};" |
    sed -n "3,${ultimoElemento}p" | sed "s/$/./g" | xargs
}

function addcarta(){
  # Opções de cores. NC serve para fechar bloco de cor.
  local PINK='\033[0;35m'
  local NC='\033[0m'

  local nomeCarta
  local qtdCarta
  local descricaoCarta
  local raridadeCarta
  declare -a local raridades
  local tipoCarta
  declare -a local tiposCarta
  local subtipoCarta
  declare -a local subtiposCarta
  local combateCarta
  local custoCarta
  declare -a local custosCarta
  local habilidadeCarta
  declare -a local habilidadesCarta

  local validacao="falso"
  local query=""
  local textoColorido=""
  local adicionaMais="Não"
  local confirmaCampo="Não"

  # Mostra todas os campos de uma carta.
  echo "Carta:"
  echo "Nome | Quantidade | Raridade | Tipo | Subtipo | Descrição | Combate | Custo | Habilidade"
  echo ""

  # Seção Nome
  while [[ "$nomeCarta" == "" ]]
  do
    read -p "Nome: " nomeCarta
    nomeCarta=$( echo "$nomeCarta" | sed "s/^ *//g" ) # Remove trailing spaces
  done

  # Seção Quantidade
  while [[ ! $qtdCarta =~ (^[0-9]$)|(^[0-9][0-9]$) ]]
  do
    read -p "Quantidade: " qtdCarta
    qtdCarta=$( echo "$qtdCarta" | sed "s/^ *//g" ) # Remove trailing spaces
  done

  # Seção Raridade
  ## Obtém do banco de dados os nomes válidos de raridade e converte em um array.
  query=$( selectQuery "raridade" "6" )

  readarray -d . -t raridades <<< "$query"
  for i in "${!raridades[@]}"
  do
    raridades[$i]=$( echo "${raridades[$i]}" | sed "s/^ *//g" ) # Remove trailing spaces
  done

  ## Exibe para o usuário todos os nomes válidos de raridade numa cor de destaque.
  textoColorido=$(
  echo "Raridades: ${raridades[@]}" |
    awk '{print $1 " " $2 ", " $3 ", " $4 ", " $5 " " $6}'
  )
  echo -e "${PINK}$textoColorido${NC}"

  ## Lê o input do usuário permitindo apenas uma entrada válida.
  while [[ "$validacao" == "falso" ]]
  do
    read -p "Raridade: " raridadeCarta
    raridadeCarta=$( echo "$raridadeCarta" | sed "s/^ *//g" ) # Remove trailing spaces
    for item in "${raridades[@]}"
    do
      if [[ "$raridadeCarta" == "$item" ]]
      then
        validacao="verdadeiro"
        break
      fi
    done
  done
  validacao="falso"

  # Seção Tipo
  # Obtém do banco de dados os nomes válidos de tipo e converte em um array.
  query=$( selectQuery "tipo" "10" )

  readarray -d . -t tipos <<< "$query"
  for i in "${!tipos[@]}"
  do
    tipos[$i]=$( echo "${tipos[$i]}" | sed "s/^ *//g" ) # Remove trailing spaces
  done

  textoColorido=$(
  echo -e "Tipos: ${tipos[@]}" |
    awk '{print $1 " " $2 ", " $3 ", " $4 ", " $5 ", " $6 " " $7 ", " $8 ", " $9 " " $10 ", " $11}'
  )
  echo -e "${PINK}$textoColorido${NC}"

  while [[ "$validacao" == "falso" ]]
  do
    read -p "Tipo: " tipoCarta
    tipoCarta=$( echo "$tipoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
    for item in "${tipos[@]}"
    do
      if [[ "$tipoCarta" == "$item" ]]
      then
        validacao="verdadeiro"
        for i in "${tiposCarta[@]}"
        do
          if [[ "$i" == "$tipoCarta" ]]
          then
            validacao="falso"
          fi
        done
        if [[ "$validacao" == "verdadeiro" ]]
        then
          tiposCarta+=( "$tipoCarta" )
          read -p "Você deseja adicionar mais algum tipo?(Sim-Não): " adicionaMais
          if [[ "${adicionaMais^}" =~ ^S  ]]
          then
            validacao="falso"
          fi
        else
          echo -e "${PINK}Você já selecionou este tipo. O script vai seguir para o próximo campo.${NC}"
        fi
        break
      fi
    done
  done
  validacao="falso"
  adicionaMais="Não"

  if [[ "${tiposCarta[0]}" =~ "Terreno Básico" ]]
  then
    echo "Falta implementar aqui adicionar a carta no banco."
  elif [[ " ${tiposCarta[*]} " =~ " Planeswalker " ]]
  then
    echo "Falta implementar aqui adicionar a carta no banco."
  else
    # Seção Subtipo
    # Obtém do banco de dados os nomes válidos de sutipo e converte em um array.
    read -p "Esta carta possui subtipo?(Sim-Não): " confirmaCampo
    if [[ "${confirmaCampo^^}" == *"S"* ]]
    then
      local subtipos=(
        $(
          psql -U postgres -d mtg -c "select nome as Subtipo from subtipo;" |
            sed -n "3,20p" | xargs
        )
      )
      textoColorido=$(
      echo -e "Subtipos: ${subtipos[@]}" | tr " " ", "
      )
      echo -e "${PINK}$textoColorido${NC}"

      while [[ ! " ${subtipos[*]} " =~ " ${subtipoCarta} " ]]
      do
        read -p "Subtipo: " subtipoCarta
        subtipoCarta=$( echo "$subtipoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
        if [[ " ${subtipos[*]} " =~ " ${subtipoCarta} " ]]
        then
          if [[ ! " ${subtiposCarta[*]} " =~ " ${subtipoCarta} " ]]
          then
            subtiposCarta+=( "$subtipoCarta" )
            read -p "Você deseja adicionar mais algum subtipo?(Sim-Não): " adicionaMais
            if [[ ${adicionaMais^^} == *"S"* ]]
            then
              subtipoCarta=""
            fi
          else
           echo -e "${PINK}Você já selecionou este campo. O script vai seguir para o próximo.${NC}"
          fi
        fi
      done
      confirmaCampo="Não"
    fi
    adicionaMais="Não"

    # Seção Descrição
    read -p "Esta carta possui descrição?(Sim-Não): " confirmaCampo
    if [[ "${confirmaCampo^^}" == *"S"* ]]
    then
      while [[ "$descricaoCarta" == "" ]]
      do
        read -p "Descrição: " descricaoCarta
        descricaoCarta=$( echo "$descricaoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
      done
      confirmaCampo="Não"
    fi

    # Seção Combate
    if [[ " ${tiposCarta[*]} " =~ " Criatura " ]]
    then
      while [[ ! $combateCarta =~ ((^[0-9X])|(^[0-9][0-9]))[/](([0-9X]$)|([0-9][0-9]$)) ]]
      do
        read -p "Combate (P/R): " combateCarta
        combateCarta=$( echo "$combateCarta" | sed "s/^ *//g" ) # Remove trailing spaces
      done
    fi

    # Seção Custo
    echo -e "${PINK}Custos: Floresta, Pântano, Ilha, Planície, Montanha, Incolor${NC}"
    while [[ ! $custoCarta =~ (^[0-9X])[/]([0-9X])[/]([0-9X])[/][0-9X][/][0-9X][/][0-9X$] ]]
    do
      read -p "Custo definido (#F/#P/#I/#Pl/#M/#In): " custoCarta
      custoCarta=$( echo "$custoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
      if [[ $custoCarta =~ (^[0-9X])[/]([0-9X])[/]([0-9X])[/][0-9X][/][0-9X$][/][0-9X$] ]]
      then
        custosCarta+=( "$custoCarta" )
        read -p "Você deseja adicionar mais algum custo?(Sim-Não): " adicionaMais
        if [[ ${adicionaMais^^} == *"S"* ]]
        then
          custoCarta=""
        fi
      fi
    done
    adicionaMais="Não"

    # Seção Habilidade
    local habilidades=(
      $(
        psql -U postgres -d mtg -c "select nome as Habilidade from habilidade;" |
          sed -n "3,14p" | xargs
      )
    )

    textoColorido=$(
    echo -e "Habilidades: ${habilidades[@]}" |
      awk '{print $1 " " $2 " " $3 " " $4 ", " $5 " " $6 ", " $7 ", " $8 ", " $9 ", " $10 ", " $11 ", " $12 " " $13 ", " $14 ", " $15 ", " $16 ", " $17 " " $18 " " $19 " " $20}'
    )
    echo -e "${PINK}$textoColorido${NC}"

    while [[ ! $combateCarta =~ ((^[0-9X])|(^[0-9][0-9]))[/](([0-9X]$)|([0-9][0-9]$)) ]]
    do
      read -p "Combate (P/R): " combateCarta
      combateCarta=$( echo "$combateCarta" | sed "s/^ *//g" ) # Remove trailing spaces
    done
    read -p "Habilidade: " habilidadeCarta
  fi
  # psql -U postgres -d mtg -c "select * from carta;"
}

addcarta

