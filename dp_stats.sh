#!/usr/bin/env bash
fd -aHp -t f --search-path Takeout/ --print0 | \
  ./usr/bin/datapacker -0 -b ./bins/%03d -s 4000m \
  '--action=exec:echo -n "$1: "; shift; du -ch "$@" | grep total' \
  -
