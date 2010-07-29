#!/usr/bin/perl
use strict;
use warnings;
use Mojo::Server::FCGI;
use FindBin;
use lib '/usr/local/dicty/lib';

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";



my $fcgi = Mojo::Server::FCGI->new(app_class => 'Resolver'); 
$fcgi->run;
