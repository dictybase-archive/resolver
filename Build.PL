#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Resolver',
    license       => 'perl',
    dist_author   => 'Siddhartha Basu <siddhartha-basu@northwestern.edu>',
    dist_abstract => 'Module for resolving Ids',
    dist_version  => '0.1',
    requires      => {
        'Mojolicious'                 => '1.21',
        'Moose'                       => '2.00',
        'Bio::Chado::Schema'          => '0.08100',
        'MooseX::Role::Parameterized' => '0.26',
        'YAML::XS'                    => '0.35',
        'Plack'                       => '0.9976',
        'Module::Versions'            => '0.02',
        'FCGI::Engine'                => '0.18',
        'MooseX::NonMoose'            => '0.20'
    },
    recommends     => { 'DBD::Oracle' => '1.28'},
    add_to_cleanup => [' Resolver- *'],
);

$builder->create_build_script();

1;
