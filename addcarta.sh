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

  # Memórias locais referentes às tabelas do banco de dados
  local nomeCarta
  local qtdCarta
  local descricaoCarta
  local raridadeCarta
  local tipoCarta
  declare -a local tiposCarta
  local subtipoCarta
  declare -a local subtipos
  declare -a local subtiposCarta
  local combateCarta
  local custoCarta
  declare -a local custosCarta
  local habilidadeCarta
  declare -a local habilidadesCarta

  # Memórias de uso geral
  local validacao="falso"
  local query=""
  local textoColorido=""
  local adicionaMais="Não"
  local confirmaCampo="Não"

  # Mostra todos os campos de uma carta.
  echo -e "${PINK}Nome | Quantidade | Raridade | Tipo | Subtipo | Descrição | Combate | Custo | Habilidade${NC}"
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
    echo "Raridades: ${raridades[@]}" | sed "s/ /,\ /g" | sed "0,/, /{s/, / /}" |
      sed "s/Mítico, Raro,/Mítico Raro/g"
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
  ## Obtém do banco de dados os nomes válidos de tipo e converte em um array.
  query=$( selectQuery "tipo" "10" )
  readarray -d . -t tipos <<< "$query"
  for i in "${!tipos[@]}"
  do
    tipos[$i]=$( echo "${tipos[$i]}" | sed "s/^ *//g" ) # Remove trailing spaces
  done

  ## Exibe para o usuário todos os nomes válidos de tipos numa cor de destaque.
  textoColorido=$(
    echo -e "Tipos: ${tipos[@]}" | sed "s/ /,\ /g" | sed "0,/, /{s/, / /}" |
      sed "s/Mágica, Instantânea/Mágica Instantânea/g" |
      sed "s/Terreno, Básico/Terreno Básico/g" |
      sed "s/Terreno,/Terreno/g"
  )
  echo -e "${PINK}$textoColorido${NC}"

  ## Lê o input do usuário permitindo apenas uma entrada válida.
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
          validacao="verdadeiro" # Força saída
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
    ## Confirma se esta carta possui subtipo
    read -p "Esta carta possui subtipo?(Sim-Não): " confirmaCampo
    if [[ "${confirmaCampo^}" =~ ^S ]]
    then
      ## Obtém do banco de dados os nomes válidos de sutipo e converte em um array.
      query=$( selectQuery "subtipo" "20" )
      readarray -d . -t subtipos <<< "$query"
      for i in "${!subtipos[@]}"
      do
        subtipos[$i]=$( echo "${subtipos[$i]}" | sed "s/^ *//g" ) # Remove trailing spaces
      done

      ## Exibe para o usuário todos os nomes válidos de subtipos numa cor de destaque.
      textoColorido=$(
        echo "Subtipos: ${subtipos[@]}" | sed "s/ /,\ /g" | sed "0,/, /{s/, / /}" |
          sed "s/Guerreiro,/Guerreio/g"
      )
      echo -e "${PINK}$textoColorido${NC}"

      ## Faz a validação
      while [[ "$validacao" == "falso" ]]
      do
        read -p "Subtipo: " subtipoCarta
        subtipoCarta=$( echo "$subtipoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
        for item in "${subtipos[@]}"
        do
          if [[ "$subtipoCarta" == "$item" ]]
          then
            validacao="verdadeiro"
            for i in "${subtiposCarta[@]}"
            do
              if [[ "$i" == "$subtipoCarta" ]]
              then
                validacao="falso"
              fi
            done
            if [[ "$validacao" == "verdadeiro" ]]
            then
              subtiposCarta+=( "$subtipoCarta" )
              read -p "Você deseja adicionar mais algum tipo?(Sim-Não): " adicionaMais
              if [[ "${adicionaMais^}" =~ ^S ]]
              then
                validacao="falso"
              fi
            else
              echo -e "${PINK}Você já selecionou este tipo. O script vai seguir para o próximo campo.${NC}"
              validacao="verdadeiro" # Força saída
            fi
            break
          fi
        done
      done
    fi
    validacao="falso"
    adicionaMais="Não"
    confirmaCampo="Não"

    # Seção Descrição
    read -p "Esta carta possui descrição?(Sim-Não): " confirmaCampo
    if [[ "${confirmaCampo^}" =~ ^S ]]
    then
      while [[ "$descricaoCarta" == "" ]]
      do
        read -p "Descrição: " descricaoCarta
        descricaoCarta=$( echo "$descricaoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
      done
    fi
    confirmaCampo="Não"

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
        if [[ ${adicionaMais^} =~ ^S ]]
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
      echo -e "Habilidades: ${habilidades[@]}" | sed "s/ /,\ /g" | sed "0,/, /{s/, / /}"
    )
    echo -e "${PINK}$textoColorido${NC}"

    while [[ ! $combateCarta =~ ((^[0-9X])|(^[0-9][0-9]))[/](([0-9X]$)|([0-9][0-9]$)) ]]
    do
      read -p "Combate (P/R): " combateCarta
      combateCarta=$( echo "$combateCarta" | sed "s/^ *//g" ) # Remove trailing spaces
    done
    read -p "Habilidade: " habilidadeCarta
  fi

  # echo "Resultado do script"
  # echo ""

  # echo "$nomeCarta"
  # echo "$qtdCarta"
  # echo "$descricaoCarta"
  # echo "$raridadeCarta"
  # echo "${tiposCarta[@]}"
  # echo "${subtiposCarta[@]}"
  # echo "$combateCarta"
  # echo "${custosCarta[@]}"
  # echo "${habilidadesCarta[@]}"

  # psql -U postgres -d mtg -c "select * from carta;"
}

addcarta

