#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Resolver',
    license       => 'perl',
    dist_author   => 'Siddhartha Basu <siddhartha-basu@northwestern.edu>',
    dist_abstract => 'Module for resolving Ids',
    dist_version  => '0.2',
    requires      => {
        'Mojolicious'                 => '1.21',
        'Moose'                       => '1.21',
        'Bio::Chado::Schema'          => '0.058',
        'MooseX::Role::Parameterized' => '0.23',
        'MooseX::NonMoose'            => '0.17',
        'MooseX::Params::Validate'    => '0.16',
        'Math::BigInt'                => '1.99',
        'Math::Base36'                => '0.09',
        'DBI'                         => '1.51',
        'DBD::Oracle'                 => '1.27',
        'namespace::autoclean'        => '0.13',
        'MooseX::Aliases'             => '0.10'
    },
    configure_requires => { 'Module::Versions' => '0.02', },
    recommends         => { 'DBD::Oracle'      => '1.27' },
    add_to_cleanup     => [' Resolver-*'],
);

$builder->create_build_script();

1;
