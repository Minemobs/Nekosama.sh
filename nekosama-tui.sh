#!/bin/bash

LANG="vostfr" # Change it to vf

if ! [ -x "$(command -v fzf)" ]; then
  echo 'Error: fzf is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

mkdir "/tmp/nekosama" &> /dev/null

function generateSequence {
  local sequence=""
  local nbrOfEpisodes=$1
  ((++nbrOfEpisodes))
  while((nbrOfEpisodes--)); do
    if [[ $nbrOfEpisodes -eq 0 ]]; then
      break
    fi
    if [[ $nbrOfEpisodes -lt 10 ]]; then
      sequence="0$nbrOfEpisodes\n$sequence"
      continue
    fi
    sequence="$nbrOfEpisodes\n$sequence"
  done
  echo -e -n $sequence
}

function custom_fzf {
  fzf --no-sort --border-label-pos 5:top --color=label:italic:red "$@"
}

JSON="$(curl -s https://neko-sama.fr/animes-search-$LANG.json)"
echo "$JSON" >| "/tmp/nekosama/$LANG.json"

if [ -x "$(command -v kitty )" ]; then
  SERIE_NAME="$(echo "$JSON" | jq -r '.[] | .title' | custom_fzf --border-label "VOSTFR Anime Selection" --height 50% --preview='kitty icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" $(cat /tmp/nekosama/'$LANG'.json | jq -r ".[{n}] | .url_image")')"
else
  SERIE_NAME="$(echo "$JSON" | jq -r '.[] | .title' | custom_fzf --border-label "VOSTFR Anime Selection" --height 50%)"
fi

if [ $? -ne 0 ]; then
  exit 0
fi

SERIE_JSON="$(echo "$JSON" | jq 'map(select(.title == "'"$SERIE_NAME"'")) | .[]')"
SERIE_URL="$(echo $SERIE_JSON | jq -r '.url')"
SERIE_PATH="$(echo "$SERIE_URL" | cut -d "/" -f 6 | cut -d '_' -f 1)"
SERIE_EPISODES="$(curl -s $SERIE_URL | grep -Eo "https://neko-sama.fr/anime/episode/[0-9]+-.+-[0-9]+_vostfr" | head -1 | grep -Eo "\-[0-9]+_" | cut -d "_" -f 1 | cut -d "-" -f 2)"
if [[ $SERIE_EPISODES != "01" ]]; then
  # shellcheck disable=SC2046
  # EPISODE="$(gum choose --header "Episode of $SERIE_NAME" $(generateSequence "$SERIE_EPISODES"))"
  EPISODE=$(generateSequence "$SERIE_EPISODES" | custom_fzf --border-label "$SERIE_NAME Episode Selection" --height 25%)
  if [ $? -ne 0 ]; then
    exit 0
  fi
else
  EPISODE="01"
fi

rm "/tmp/nekosama/$LANG.json" &> /dev/null
printf "https://neko-sama.fr/anime/episode/%s-%s_vostfr\n" "$SERIE_PATH" "$EPISODE"
