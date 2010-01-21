#!/usr/bin/env perl

use strict;
use warnings;

use Mojo::Client;
use Mojo::Transaction;
use Test::More qw/no_plan/;

use_ok('Resolver');

# Prepare client and transaction
my $client = Mojo::Client->new;

#gene id
my $tx     = Mojo::Transaction->new_get('/id/DPU_G0051088');
# Process request
$client->process_app('Resolver', $tx);
# Test response
is($tx->res->code, 301,  'got redirection for gene id');


#for transcript
$tx     = Mojo::Transaction->new_get('/id/DPU0051089');
# Process request
$client->process_app('Resolver', $tx);
# Test response
is($tx->res->code, 301,  'got redirection for mRNA id');


#for est
$tx     = Mojo::Transaction->new_get('/id/DPU0029921');
# Process request
$client->process_app('Resolver', $tx);
# Test response
is($tx->res->code, 301,  'got redirection for EST id');

#wrong id
$tx     = Mojo::Transaction->new_get('/id/halo');
# Process request
$client->process_app('Resolver', $tx);
# Test response
is($tx->res->code, 404,  'Got correct response');
like($tx->res->body, qr/not found/,  'the id not found');






