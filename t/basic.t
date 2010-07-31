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
my $tx = Mojo::Transaction->new_get('/id/DPU_G0051088');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for gene id' );
like( $tx->res->headers->location,
    qr/purpureum/,
    'has purpureum as species in the redirected header of gene' );

$tx = Mojo::Transaction->new_get('/id/DPU_G0069236');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for gene id' );
like( $tx->res->headers->location,
    qr/purpureum/,
    'has purpureum as species in the redirected header of gene' );

#for transcript
$tx = Mojo::Transaction->new_get('/id/DPU0051089');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for mRNA id' );
like( $tx->res->headers->location,
    qr/DPU_G0051088/, 'has gene id in the redirected header of transcript' );

#for est
$tx = Mojo::Transaction->new_get('/id/DPU0029921');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for EST id' );
like( $tx->res->headers->location,
    qr/feature_page/, 'has legacy url in the redirected header of est' );
unlike( $tx->res->headers->location,
    qr/purpureum/,
    'should not have species name in the redirected header of est' );
#diag( Dumper $tx->res->headers->location );

#for supercontig
$tx = Mojo::Transaction->new_get('/id/DPU0000186');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for supercontig id' );
like( $tx->res->headers->location,
    qr/feature_page/,
    'has legacy url in the redirected header of supercontig' );
unlike( $tx->res->headers->location,
    qr/purpureum/,
    'should not have species name in the redirected header of supercontig' );

#wrong id
$tx = Mojo::Transaction->new_get('/id/halo');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 404, 'Got correct response' );
like( $tx->res->body, qr/cannot be mapped/, 'the id not found' );

#some dictybase id
$tx = Mojo::Transaction->new_get('/id/DDB_G0277399');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for dictybase gene id' );
like( $tx->res->headers->location,
    qr/discoideum/, 'has discoideum as species in the redirected header' );
like( $tx->res->headers->location,
    qr/gene/, 'has gene types in the redirected header' );

#now some dictybase transcript id
$tx = Mojo::Transaction->new_get('/id/DDB0185055');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for dictybase transcript id' );
like( $tx->res->headers->location,
    qr/discoideum/,
    'has discoideum as species in the redirected header of transcript' );
like( $tx->res->headers->location,
    qr/DDB_G0277399/, 'has gene id in the redirected header of transcript' );

#now some dictybasse est id
$tx = Mojo::Transaction->new_get('/id/DDB0076691');

# Process request
$client->process_app( 'Resolver', $tx );

# Test response
is( $tx->res->code, 301, 'got redirection for dictybase est id' );
like( $tx->res->headers->location,
    qr/feature_page/,
    'has legacy url in the redirected header of dictybase est' );
like( $tx->res->headers->location,
    qr/discoideum/,
    'should have species name in the redirected header of est' );
