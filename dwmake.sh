#!/bin/bash

makedwmakefile()
{
  echo "What target are you building?"
  echo "1. EXEC"
  echo "2. DYNAMIC_LIB" 
  echo "3. STATIC_LIB" 
  echo "4. DYNAMIC_PLUGIN" 
  echo -n "[1]: "

  target="EXEC"
  read ans
  echo ans is ==${ans}==


  case ${ans} in 
    1) target="EXEC";;
    2) target="DYNAMIC_LIB" ;;
    3) target="STATIC_LIB" ;;
    4) target="DYNAMIC_PLUGIN";;
    *) ;;
  esac


  case ${target} in
    EXEC)
      echo -n "EXEC name? "
         read name;
         echo "EXEC = " $name >> .dwmake
           ;;

  esac
}


if [ ! -f .dwmake ]
then
  /usr/bin/make $*
  exit 0
else
  WD=`pwd`
  make WD="${WD}" -C ${WD} --makefile=${DWMAKE}/dwmake.mk $*
fi


exit 0


