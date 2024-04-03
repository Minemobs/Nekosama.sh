#!/bin/bash
if ! [ -x "$(command -v gum)" ]; then
  echo 'Error: gum is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

function generateSequence {
  local sequence=""
  local nbrOfEpisodes=$1
  ((++nbrOfEpisodes))
  while((nbrOfEpisodes--)); do
    if [[ $nbrOfEpisodes -eq 0 ]]; then
      break
    fi
    if [[ $nbrOfEpisodes -lt 10 ]]; then
      sequence="0$nbrOfEpisodes $sequence"
      continue
    fi
    sequence="$nbrOfEpisodes $sequence"
  done
  echo "$sequence"
}

JSON="$(curl -s https://neko-sama.fr/animes-search-vostfr.json)"

SERIE_NAME="$(echo "$JSON" | jq -r '.[] | .title' | gum filter)"
if [ $? -ne 0 ]; then
  exit 0
fi
# printf "User choose to watch '%s'\n" "$SERIE_NAME"
SERIE_JSON="$(echo "$JSON" | jq 'map(select(.title == "'"$SERIE_NAME"'")) | .[]')"
SERIE_URL="$(echo "$SERIE_JSON" | jq -r '.url' | cut -d "/" -f 4 | cut -d '_' -f 1)"
SERIE_EPISODES="$(echo "$SERIE_JSON" | jq -r '.nb_eps' | cut -d " " -f 1)"
if [[ $SERIE_EPISODES != "Film" ]]; then
  EPISODE="$(gum choose --header "Episode of $SERIE_NAME" $(generateSequence "$SERIE_EPISODES"))"
  if [ $? -ne 0 ]; then
    exit 0
  fi
else
  EPISODE="01"
fi
printf "https://neko-sama.fr/anime/episode/%s-%s_vostfr\n" "$SERIE_URL" "$EPISODE"
