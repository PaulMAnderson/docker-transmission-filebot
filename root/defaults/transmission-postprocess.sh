#!/bin/bash

TIMEDATE=$(date '+%Y-%m-%d %H:%M:%S')
echo $TIMEDATE "Processing" $TR_TORRENT_NAME >> /config/logs/torrents.processed.log

# transmission-remote --auth a1118507:b8AnBEBTLw2PkWrqBApW87ojiNGURLhEFBj9onZZeJkry9DFD9GNwQwq3tF2R6Dd -t $TR_TORRENT_ID -r

/usr/local/bin/filebot -script fn:amc --output "/" --action move --conflict auto -non-strict --def "minFileSize=0" "minLengthMS=0" "ut_dir=$TR_TORRENT_DIR/$TR_TORRENT_NAME" "ut_kind=multi" "ut_title=$TR_TORRENT_NAME" clean=y artwork=n subtitles=en "seriesFormat=series/{n}/{n} Season {s}/{n} {s00e00} - {t}" "animeFormat=anime/Anime Series/{n}/{n} Season {s}/{n} {order.airdate.s00e00} - {t}" "movieFormat=movies/{n} ({y})/{n} ({y})" --log-file "/config/logs/filebot.transmission.script.log"

TIMEDATE=$(date '+%Y-%m-%d %H:%M:%S')
echo $TIMEDATE "Processed" $TR_TORRENT_NAME >> /config/logs/torrents.processed.log