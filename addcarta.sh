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
# Opções de cores. NC serve para fechar bloco de cor.
PINK='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m'

function getCombateId(){
  local combateCarta=$1
  local poder=$( echo "$combateCarta" | sed "s/[/].*$//g" )
  local resistencia=$( echo "$combateCarta" | sed "s/^.*[/]//g" )

  psql -U postgres -d mtg -c "select id from combate where poder=${poder} and resistencia=${resistencia};" | sed -n "3,3p"
}

function selectQuery(){
  local tabela=$1
  local ultimoElemento=$2

  psql -U postgres -d mtg -c "select nome as ${tabela^} from ${tabela};" |
    sed -n "3,${ultimoElemento}p" | sed "s/$/./g" | xargs
}

function confirm(){
  local texto=$1
  local confirmaCampo

  read -p "$(echo -e ${YELLOW}"Esta carta possui $texto?(Sim-Não): "${NC})" confirmaCampo

  echo "$confirmaCampo"
}

function validateArray(){
  local mensagemLeitura=$1 # Mensagem que aparece para o usuário informar o valor
  local queryArray=("$@") # Array com o resultado da query select

  local inputCarta="" # Entrada do usuário sobre a informação da carta
  local adicionaMais="Não" # Confirma se mais algum elemento é necessário
  local validacao="falso"

  declare -a local outputArray

  ## Lê o input do usuário permitindo apenas uma entrada válida.
  while [[ "$validacao" == "falso" ]]
  do
    read -p "${mensagemLeitura^}: " inputCarta
    inputCarta=$( echo "$inputCarta" | sed "s/^ *//g" ) # Remove trailing spaces
    for item in "${queryArray[@]}"
    do
      if [[ "$inputCarta" == "$item" ]]
      then
        validacao="verdadeiro"
        for i in "${outputArray[@]}"
        do
          if [[ "$i" == "$inputCarta" ]]
          then
            validacao="falso"
          fi
        done
        if [[ "$validacao" == "verdadeiro" ]]
        then
          outputArray+=( "$inputCarta" )
          read -p "$(echo -e ${YELLOW}"Você deseja adicionar mais algum ${mensagemLeitura}?(Sim-Não): "${NC})" adicionaMais
          if [[ "${adicionaMais^}" =~ ^S ]]
          then
            validacao="falso"
          fi
        else
          echo -e "${PINK}Você já adicionou este ${mensagemLeitura}. O script seguirá para o próximo campo.${NC}"
          validacao="verdadeiro" # Força saída
        fi
        break
      fi
    done
  done

  echo "${outputArray[@]}"

}

function addcarta(){
  # Memórias referentes às tabelas do banco de dados
  local nomeCarta
  local qtdCarta
  local descricaoCarta
  local raridadeCarta
  local combateCarta
  declare -a local tipos
  declare -a local tiposCarta
  declare -a local subtipos
  declare -a local subtiposCarta
  local custoCarta
  declare -a local custosCarta
  declare -a local habilidadesCarta

  # Memórias de uso geral
  local query=""
  local textoColorido=""
  local validacao="falso"
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
    echo "Tipos: ${tipos[@]}" | sed "s/ /,\ /g" | sed "0,/, /{s/, / /}" |
      sed "s/Mágica, Instantânea/Mágica Instantânea/g" |
      sed "s/Terreno, Básico/Terreno Básico/g" |
      sed "s/Terreno,/Terreno/g"
  )
  echo -e "${PINK}$textoColorido${NC}"

  tiposCarta=( $(validateArray "tipo" "${tipos[@]}") )

  # Seção Custo
  echo -e "${PINK}Custos: Floresta, Pântano, Ilha, Planície, Montanha, Incolor${NC}"
  while [[ "$validacao" == "falso" ]]
  do
    read -p "Custo (#F/#P/#I/#Pl/#M/#In): " custoCarta
    custoCarta=$( echo "$custoCarta" | sed "s/^ *//g" ) # Remove trailing spaces

    if [[ $custoCarta =~ (^[0-9X])[/]([0-9X])[/]([0-9X])[/][0-9X][/][0-9X$][/][0-9X$] ]]
    then
      if [[ ! " ${custosCarta[*]} " =~ " $custoCarta " ]]
      then
        custosCarta+=( "$custoCarta" )

        read -p "$( echo -e ${YELLOW}"Você deseja adicionar mais algum custo?(Sim-Não): "${NC})" adicionaMais
        if [[ ${adicionaMais^} =~ ^S ]]
        then
          validacao="falso"
        else
          validacao="verdadeiro"
        fi
      else
        echo -e "${PINK}Você já adicionou este custo. O script seguirá para o próximo campo.${NC}"
        validacao="verdadeiro" # Força saída
      fi
    fi
  done
  adicionaMais="Não"
  validacao="falso"

  # Campos que não são obrigatórios para todas as cartas
  if [[ "${tiposCarta[0]}" =~ "Terreno Básico" ]]
  then
    echo "Falta implementar aqui adicionar a carta no banco."
  elif [[ " ${tiposCarta[*]} " =~ " Planeswalker " ]]
  then
    echo "Falta implementar aqui adicionar a carta no banco."
  else
    # Seção Subtipo
    ## Confirma se esta carta possui subtipo
    confirmaCampo=$( confirm "subtipo" )
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

      subtiposCarta=( $(validateArray "subtipo" "${subtipos[@]}") )
    fi
    confirmaCampo="Não"

    # Seção Descrição
    confirmaCampo=$( confirm "descrição" )
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
      validacao="verdadeiro"
    else
      confirmaCampo=$( confirm "poder e resisteância" )
      if [[ "${confirmaCampo^}" =~ ^S ]]
      then
        validacao="verdadeiro"
      fi
    fi

    if [[ "$validacao" == "verdadeiro" ]]
    then
      while [[ ! $combateCarta =~ ((^[0-9X])|(^[0-9][0-9]))[/](([0-9X]$)|([0-9][0-9]$)) ]]
      do
        read -p "Poder/Resistência: " combateCarta
        combateCarta=$( echo "$combateCarta" | sed "s/^ *//g" ) # Remove trailing spaces
      done
    fi
    confirmaCampo="Não"
    validacao="falso"

    # Seção Habilidade
    read -p "$(echo -e ${YELLOW}"Esta carta possui habilidade?(Sim-Não): "${NC})" confirmaCampo
    if [[ "${confirmaCampo^}" =~ ^S ]]
    then
      ## Obtém do banco de dados os nomes válidos de habilidade e converte em um array.
      query=$( selectQuery "habilidade" "14" )
      readarray -d . -t habilidades <<< "$query"
      for i in "${!habilidades[@]}"
      do
        habilidades[$i]=$( echo "${habilidades[$i]}" | sed "s/^ *//g" ) # Remove trailing spaces
      done

      ## Exibe para o usuário todos os nomes válidos de habilidade numa cor de destaque.
      textoColorido=$(
        echo "Habilidades: ${habilidades[@]}" | sed "s/ /,\ /g" | sed "0,/, /{s/, / /}" |
          sed "s/Resistência, a, magia/Resistência a magia/g" |
          sed "s/Toque, Mortífero/Toque Mortífero/g" |
          sed "s/Golpe, Duplo/Golpe Duplo/g" |
          sed "s/Vínculo, com, a, Vida,/Vínculo com a Vida/g"
      )
      echo -e "${PINK}$textoColorido${NC}"

      habilidadesCarta=( $(validateArray "habilidade" "${habilidades[@]}") )
    fi
    confirmaCampo="Não"

  fi

  # psql -U postgres -d mtg -c "insert into carta (<campo>) values (<value>);"
  # Insert na tabela carta
  if [[ "$descricaoCarta" != "" ]]
  then
    if [[ "$combateCarta" != "" ]]
    then
      local combateId=$( getCombateId "$combateCarta" )

      psql -u postgres -d mtg -c "insert into carta (quantidade, nome, raridade, descricao, combate) values (${qtdcarta}, ${nomecarta}, ${raridadecarta}, ${descricaocarta}, ${combateid});"
    else
      psql -u postgres -d mtg -c "insert into carta (quantidade, nome, raridade, descricao) values (${qtdcarta}, ${nomecarta}, ${raridadecarta}, ${descricaocarta});"
    fi
  else
    if [[ "$combateCarta" != "" ]]
    then
      local combateId=$( getCombateId "$combateCarta" )

      psql -u postgres -d mtg -c "insert into carta (quantidade, nome, raridade, combate) values (${qtdcarta}, ${nomecarta}, ${raridadecarta}, ${combateid});"
    else
      psql -u postgres -d mtg -c "insert into carta (quantidade, nome, raridade) values (${qtdcarta}, ${nomecarta}, ${raridadecarta});"
    fi
  fi

  # Insert na tabela carta_tipo
  for i in "${!tiposCarta[@]}"
  do
    psql -u postgres -d mtg -c "insert into carta_tipo (carta, tipo) values (${nomeCarta}, ${tiposCarta[$i]});"
  done

  # Insert na tabela carta_subtipo
  for i in "${!subtiposCarta[@]}"
  do
    psql -u postgres -d mtg -c "insert into carta_subtipo (carta, subtipo) values (${nomeCarta}, ${subtiposCarta[$i]});"
  done

  # Adiciona na tabela carta_custoindefinido
  custoIncolor=$( echo "$custosCarta[0]" | sed "s/.[/].[/].[/].[/].[/]//g" )
  if [[ "$custoIncolor" != "" ]]
  then
    psql -u postgres -d mtg -c "insert into carta_custoindefinido (carta, custoindefinido) values (${nomeCarta}, ${custoIncolor});"
  fi
  # Adiciona na tabela carta_custodefinido
  for i in "${!custoCarta[@]}"
  do
    local grupo=$(( $i + 1 ))
    local custoFloresta=$( echo "${custosCarta[$i]}" | sed "s/[/].[/].[/].[/].[/].$//g" )
    local custoPantano=$( echo "${custosCarta[$i]}" | sed "s/^.[/]//g" | sed "s/[/].[/].[/].[/].$//g" )
    local custoIlha=$( echo "${custosCarta[$i]}" | sed "s/^.[/].[/]//g" | sed "s/[/].[/].[/].$//g" )
    local custoPlanicie=$( echo "${custosCarta[$i]}" | sed "s/^.[/].[/].[/]//g" | sed "s/[/].[/].$//g" )
    local custoMontanha=$( echo "${custosCarta[$i]}" | sed "s/^.[/].[/].[/].[/]//g" | sed "s/[/].$//g" )

    if [[ "$custoFloresta" != "0" ]]
    then
      psql -u postgres -d mtg -c "insert into carta_custodefinido (carta, grupo, mana, custo) values (${nomeCarta}, ${grupo}, Floresta, ${custoFloresta});"
    fi

    if [[ "$custoPantano" != "0" ]]
    then
      psql -u postgres -d mtg -c "insert into carta_custodefinido (carta, grupo, mana, custo) values (${nomeCarta}, ${grupo}, Pântano, ${custoPantano});"
    fi

    if [[ "$custoIlha" != "0" ]]
    then
      psql -u postgres -d mtg -c "insert into carta_custodefinido (carta, grupo, mana, custo) values (${nomeCarta}, ${grupo}, Ilha, ${custoIlha});"
    fi

    if [[ "$custoPlanicie" != "0" ]]
    then
      psql -u postgres -d mtg -c "insert into carta_custodefinido (carta, grupo, mana, custo) values (${nomeCarta}, ${grupo}, Planície, ${custoPlanicie});"
    fi

    if [[ "$custoMontanha" != "0" ]]
    then
      psql -u postgres -d mtg -c "insert into carta_custodefinido (carta, grupo, mana, custo) values (${nomeCarta}, ${grupo}, Montanha, ${custoMontanha});"
    fi
  done

  # Adiciona na tabela carta_habilidade
  for i in "${!habilidadesCarta[@]}"
  do
    psql -u postgres -d mtg -c "insert into carta_habilidade (carta, habilidade) values (${nomeCarta}, ${habilidadesCarta[$i]});"
  done

}

addcarta

