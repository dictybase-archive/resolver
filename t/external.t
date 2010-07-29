#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::Client;
use Mojo::Transaction;
use Test::More qw/no_plan/;
use Data::Dumper;

use_ok('Resolver');

# Prepare client and transaction
my $client = Mojo::Client->new;

#gene id
my $tx = Mojo::Transaction->new_get('/id/0051088');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for external id' );
like( $tx->res->headers->location,
    qr/gernot/,
    'has gernot as external link provider' );
