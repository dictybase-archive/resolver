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
my $id = '33102';
my $tx = Mojo::Transaction->new_get( '/id/' . $id );

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for external id' );
like( $tx->res->headers->location, qr/$id/, 'has id in the url' );
like( $tx->res->headers->location,
    qr/leibniz/, 'has institute signature in the url' );
