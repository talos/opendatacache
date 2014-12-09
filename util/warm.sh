for supported_portal in $(cat $1); do
  python util/warm.py $2 ${supported_portal} >$3 2>$4 &
done
