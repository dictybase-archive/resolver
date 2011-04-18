#!/usr/bin/env perl

use strict;
use Test::More qw/no_plan/;
use Test::Mojo;

my $mode;

BEGIN {
    $mode = $ENV{MOJO_MODE} ? $ENV{MOJO_MODE} : undef;
    $ENV{MOJO_MODE} = 'test';
}


use_ok('Resolver');
my $t = Test::Mojo->new( app => 'Resolver' );

#gene id
my $client = $t->get_ok('/id/DPU_G0051088');
$client->status_is( 301, 'it redirects for gene id' );
$client->header_like(
    Expect => qr/purpureum/,
    'has purpureum as species in header of gene id redirection'
);

#for transcript
$client = $t->get_ok('/id/DPU0051089');
$client->status_is( 301, 'it redirects for transcript id' );
$client->header_like(
    Expect => qr/DPU_G0051088/,
    'has gene id in header of transcript id redirection'
);

#for est
$client = $t->get_ok('/id/DPU0029921');
$client->status_is( 301, 'it  redirects for est' );
$client->header_like(
    Expect => qr/feature_page/,
    'has legacy url in header of est redirection'
);

#for supercontig
$client = $t->get_ok('/id/DPU0000186');
$client->status_is( 301, 'it redirects for supercontig' );
$client->header_like(
    Expect => qr/feature_page/,
    'has legacy url in header of supercontig redirection'
);

#wrong id
$client = $t->get_ok('/id/halo');
$client->status_is( 404, 'it does not redirect' );
$client->header_like(
    Expect => qr/cannot be mapped/,
    'it cannot resolve the id'
);

#some dictybase id
$client = $t->get_ok('/id/DDB_G0277399');
$client->status_is( 301, 'it redirects for dictybase gene id' );
$client->header_like(
    Expect => qr/discoideum/,
    'has discoideum as species in the header'
);
$client->header_like(
    Expect => qr/gene/,
    'has gene types in the redirected header'
);

#now some dictybase transcript id
$client = $t->get_ok('/id/DDB0185055');
$client->status_is( 301, 'it redirects for dictybase transcript id' );
$client->header_like(
    Expect => qr/discoideum/,
    'has discoideum as species in  header of dictybase transcript id'
);
$client->header_like(
    Expect => qr/DDB_G0277399/,
    'has gene id in header of dictybase transcript id'
);

#now some dictybasse est id
$client = $t->get_ok('/id/DDB0076691');
$client->status_is( 301, 'it redirects for dictybase est id' );
$client->header_like(
    Expect => qr/feature_page/,
    'has legacy url in header of dictybase est id'
);
$client->header_like(
    Expect => qr/discoideum/,
    'has species name in header of dictybase est id'
);


END {
    $ENV{MOJO_MODE} = $mode ? $mode : undef;
}
