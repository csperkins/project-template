#!/bin/sh

if [ $# = 0 ]; then
 echo "usage: bin/check-for-todo.sh <file> ..."
 exit 1
fi
 
egrep -H -i -n --color "\\\\todo\\{" $* | grep -v ".*%.*\\\\todo" || true
 
