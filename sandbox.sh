unset PERL5LIB
unset PERL_MM_OPT
unset INSTALL_BASE

echo setting local lib to $PWD/bundle-5.8
eval $(perl -Mlocal::lib=$PWD/bundle-5.8)

echo please run '**' cpanm -L bundle --installdeps '.' '**' from this $PWD directory
echo to install all dependencies
echo and then deploy through sandbox environment

