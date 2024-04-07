#!/bin/bash
if ! [ -x "$(command -v fzf)" ]; then
  echo 'Error: fzf is not installed.' >&2
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
      sequence="0$nbrOfEpisodes\n$sequence"
      continue
    fi
    sequence="$nbrOfEpisodes\n$sequence"
  done
  echo -e -n $sequence
}

function custom_fzf {
  fzf --border-label-pos 5:top --color=label:italic:red "$@"
}

JSON="$(curl -s https://neko-sama.fr/animes-search-vostfr.json)"

SERIE_NAME="$(echo "$JSON" | jq -r '.[] | .title' | custom_fzf --border-label "VOSTFR Anime Selection" --height 50%)"
if [ $? -ne 0 ]; then
  exit 0
fi
SERIE_JSON="$(echo "$JSON" | jq 'map(select(.title == "'"$SERIE_NAME"'")) | .[]')"
SERIE_URL="$(echo "$SERIE_JSON" | jq -r '.url' | cut -d "/" -f 4 | cut -d '_' -f 1)"
SERIE_EPISODES="$(curl https://neko-sama.fr"$(echo "$SERIE_JSON" | jq -r '.url')" | grep --only-matching -E "episodes = \[\{.+\]" | cut -d "=" -f 2 | jq .[-1].num)"
if [[ $SERIE_EPISODES != "Film" ]]; then
  # shellcheck disable=SC2046
  # EPISODE="$(gum choose --header "Episode of $SERIE_NAME" $(generateSequence "$SERIE_EPISODES"))"
  EPISODE=$(generateSequence "$SERIE_EPISODES" | custom_fzf --border-label "$SERIE_NAME Episode Selection" --height 25%)
  if [ $? -ne 0 ]; then
    exit 0
  fi
else
  EPISODE="01"
fi
printf "https://neko-sama.fr/anime/episode/%s-%s_vostfr\n" "$SERIE_URL" "$EPISODE"
