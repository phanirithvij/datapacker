#!/usr/bin/env bash

# utc google takeout output format
datt=$(date -u +%Y%m%dT%H%M%SZ)
cwd=$(pwd)

original_arg=$1
# https://stackoverflow.com/a/13118192/8608146
cat << EOF > /tmp/takeoutscript.sh
#!/usr/bin/env bash
target=\$1
shift
while test \$# -gt 0
do
    curr=\$1
    # no \ for original_arg
    relp=\$(realpath --relative-to="$original_arg" "\$curr")
    mkdir -p "\$(dirname "\$target/\$relp")"
    ln "\$1" "\$target/\$relp"
    shift
done
EOF

fd -aHp -t f --search-path $1 --print0 | \
  ./usr/bin/datapacker -0 -D -b ./takeout/takeout-${datt}-%03d -s 4000m \
  '--action=exec:sh /tmp/takeoutscript.sh $argv[2..-1]' \
  -
  # chsh to bash this works
  # '--action=exec:sh /tmp/takeoutscript.sh "$@"' \
