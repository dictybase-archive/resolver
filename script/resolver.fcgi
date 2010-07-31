#!/usr/bin/env perl
use strict;
use local::lib '/home/ubuntu/dictyBase/Libs/modern-perl';
use Mojo::Server::FCGI;
use FindBin;
use lib '/usr/local/dicty/lib';

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

BEGIN {
	$ENV{MOJO_MODE} = 'production';
	$ENV{MOJO_DEBUG} = 'error';
};

my $fcgi = Mojo::Server::FCGI->new(app_class => 'Resolver'); 
$fcgi->run;
