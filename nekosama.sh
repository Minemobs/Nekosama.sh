#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Illegal number of parameters" >&2
    exit 2
fi

function fail {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

function ccurl {
    curl "$1" -s --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/jxl,image/webp,*/*;q=0.8, image/jxl' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'DNT: 1' -H 'Sec-GPC: 1' -H 'Alt-Used: fusevideo.io' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-User: ?1'
}

mkdir "/tmp/nekosama" || true

ANIME_NAME=$(echo "$1" | rev | cut -d "/" -f 1 | rev)
echo "Getting the Video provider's URL for $ANIME_NAME"
VIDEO_PROVIDER_URL=$(ccurl "$1" | grep -E "\s+video\[0\] = 'https://.+'" | cut -d "'" -f 2)
URL=""

fv_parse () {
    #Actual code
    echo "Getting the M3U8 file"
    local FV_GET_JS_SCRIPT=$(ccurl "$VIDEO_PROVIDER_URL" | grep "https://fusevideo.io/f/u/u/u/u" | cut -d '"' -f 2)
    local FV_GET_M3U8_URL=$(ccurl "$FV_GET_JS_SCRIPT" | grep -o -E "\(n=atob\(\".+=\")" | cut -d "\"" -f 2 | base64 --decode | grep -o -E "https:.+\"" | cut -d "\"" -f 1 | sed 's/\\\//\//g')
    echo "Parsing the M3U8"
    URL=$(ccurl "$FV_GET_M3U8_URL" | grep "https://" | head -n 1)
}

case "$VIDEO_PROVIDER_URL" in
    "https://fusevideo.io"*)
        # echo "Fuse video"
        fv_parse
        echo "Done:" "$URL";;
    *)
        echo "$VIDEO_PROVIDER_URL" "isn't supported yet"
        exit 1;;
esac

old_pwd=$(pwd)

mkdir "/tmp/nekosama/$ANIME_NAME" || fail "Couldn't create directory in /tmp/nekosama" 3
cd "/tmp/nekosama/$ANIME_NAME" || fail "Couldn't CD in /tmp/$ANIME_NAME" 4
M3U_URLS=$(ccurl "$URL" | grep -E "^https://")
curl --remote-name-all --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 40 $M3U_URLS || fail "Couldn't download all .ts files" 5
for i in $(\ls *.ts | sort -V); do echo "file '$i'"; done >> mylist.txt && ffmpeg -f concat -i mylist.txt -c copy -bsf:a aac_adtstoasc video.mp4 && rm *.ts && rm mylist.txt

cd "$old_pwd" || exit
mpv "/tmp/nekosama/$ANIME_NAME/video.mp4"
rm -rf "/tmp/nekosama/$ANIME_NAME"
