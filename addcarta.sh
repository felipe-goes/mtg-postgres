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

function addcarta(){
  # Opções de cores. NC serve para fechar bloco de cor.
  local PINK='\033[0;35m'
  local NC='\033[0m'

  local nomeCarta
  local qtdCarta
  local descricaoCarta
  local raridadeCarta
  local tipoCarta
  local subtipoCarta
  local combateCarta
  local custoCarta
  local habilidadeCarta

  # Mostra todas os campos de uma carta.
  echo "Carta:"
  echo "Nome | Quantidade | Descrição | Raridade | Tipo | Subtipo | Combate | Custo | Habilidade"
  echo ""

  # Lê campos básicos. Os dados não precisam ser tratados.
  while [[ "$nomeCarta" == "" ]]
  do
    read -p "Nome: " nomeCarta
    nomeCarta=$( echo "$nomeCarta" | sed "s/^ *//g" ) # Remove trailing spaces
  done
  while [[ ! $qtdCarta =~ (^[0-9]$)|(^[0-9][0-9]$) ]]
  do
    read -p "Quantidade: " qtdCarta
    qtdCarta=$( echo "$qtdCarta" | sed "s/^ *//g" ) # Remove trailing spaces
  done
  read -p "Descrição: " descricaoCarta
  descricaoCarta=$( echo "$descricaoCarta" | sed "s/^ *//g" ) # Remove trailing spaces

  # Seção Raridade
  ## Obtém do banco de dados os nomes válidos de raridade e converte em um array.
  local raridades=( 
    $(
      psql -U postgres -d mtg -c "select nome as Raridade from raridade;" |
        sed -n "3,6p" | xargs
    )
  )
  raridades[-2]="${raridades[-2]} ${raridades[-1]}"
  unset raridades[-1]

  ## Exibe para o usuário todos os nomes válidos de raridade numa cor de destaque.
  local textoColorido=$(
  echo -e "Raridades: ${raridades[@]}" |
    awk '{print $1 " " $2 ", " $3 ", " $4 ", " $5 " " $6}'
  )
  echo -e "${PINK}$textoColorido${NC}"

  ## Lê o input do usuário permitindo apenas uma entrada válida.
  while [[ ! " ${raridades[*]} " =~ " ${raridadeCarta} " ]]
  do
    read -p "Raridade: " raridadeCarta
    raridadeCarta=$( echo "$raridadeCarta" | sed "s/^ *//g" ) # Remove trailing spaces
  done

  # Seção Tipo
  # Obtém do banco de dados os nomes válidos de tipo e converte em um array.
  local tipos=( 
    $(
      psql -U postgres -d mtg -c "select nome as Tipo from tipo;" |
        sed -n "3,10p" | xargs
    )
  )
  textoColorido=$(
  echo -e "Tipos: ${tipos[@]}" |
    awk '{print $1 " " $2 ", " $3 ", " $4 ", " $5 ", " $6 " " $7 ", " $8 ", " $9 " " $10 ", " $11}'
  )
  echo -e "${PINK}$textoColorido${NC}"
  local tiposCarta=()

  local adicionaMais="Não"
  while [[ ! " ${tipos[*]} " =~ " ${tipoCarta} " ]]
  do
    read -p "Tipo: " tipoCarta
    tipoCarta=$( echo "$tipoCarta" | sed "s/^ *//g" ) # Remove trailing spaces
    if [[ " ${tipos[*]} " =~ " ${tipoCarta} " ]]
    then
      if [[ ! " ${tiposCarta[*]} " =~ " ${tipoCarta} " ]]
      then
        tiposCarta+=( "$tipoCarta" )
        read -p "Você deseja adicionar mais algum tipo?(Sim-Não): " adicionaMais
        if [[ ${adicionaMais^^} == *"S"* ]]
        then
          tipoCarta=""
        fi
      else
       echo "Você já selecionou este campo. O script vai seguir para o próximo."
      fi
    fi
  done
  # while [[ "${#tiposCarta[@]}" == 0 ]]
  # do
  #   while [[ "$tipoCarta" != "" ]]
  #   do
  #     read -p "Tipo: " tipoCarta
  #     if [[ "$tipoCarta" != "" ]]
  #     then
  #       tiposCarta+=( "$tipoCarta" )
  #     fi
  #   done
  # done
  # if [[ "$tipoCarta" == "Criatura" ]]

  read -p "Subtipo: " subtipoCarta
  read -p "Combate: " combateCarta
  read -p "Custo: " custoCarta
  read -p "Habilidade: " habilidadeCarta
  # psql -U postgres -d mtg -c "select * from carta;"
}

addcarta

