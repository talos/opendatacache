export REGEX=$(head -c -1 $2 | tr '\n' '|') && sed s/__PROXY_REGEX__/$(echo ${REGEX})/ $1
