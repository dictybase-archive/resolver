#!/bin/bash

bundle=bundle

if [ $# -eq 1 ] 
then
 if [ "$1" = "-h" ]
 then
   echo >&2 usage: $0 [local-lib-folder]
   echo >&2 ' sets up local lib environment for the given folder'
   echo >&2 ' default is *bundle* in current directory'
   exit 0
  else
    bundle=$1
 fi
fi


echo unsetting standard local-lib variables

unset PERL5LIB
unset PERL_MM_OPT
unset INSTALL_BASE

folder=$PWD/$bundle
echo setting local lib to $folder
eval $(perl -Mlocal::lib=$folder)

echo please run ' **' cpanm -L $folder --installdeps '.' '**' from this $PWD directory
echo '  to install all dependencies'
echo '  and then deploy through sandbox environment'
echo ' ... all is well ....'

