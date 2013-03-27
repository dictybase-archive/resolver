#!/usr/bin/env perl

use strict;
use Test::More qw/no_plan/;
use Test::Mojo;


my $mode;

BEGIN {
    $mode = $ENV{MOJO_MODE} ? $ENV{MOJO_MODE} : undef;
    $ENV{MOJO_MODE} = 'test';
    #$ENV{MOJO_LOG_LEVEL} = 'debug';
}

use_ok('Resolver');
my $t = Test::Mojo->new( app => 'Resolver' );

my $id = '33102';
my $client = $t->get_ok( '/id/' . $id );
$client->status_is( 302, 'it redirects for external id' );
$client->header_like(location => qr/$id/, 'has id in the url' );
$client->header_like(location => qr/leibniz/, 'has institute signature in the url' );


END {
	$ENV{MOJO_MODE} = $mode if defined $mode;
}
