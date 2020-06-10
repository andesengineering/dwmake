#!/bin/bash

bye()
{
    echo $1
    exit 1
}

[ -z "${DWMAKE}" ] && bye "DWMAKE environmental variable not set.  DWMAKE should be set to the directory where dwmake.mk is contained"

if [ ! -f .dwmake ]
then
    exec /usr/bin/make $*
else
    exec /usr/bin/make --makefile=${DWMAKE}/dwmake.mk $*
fi

exit 0


