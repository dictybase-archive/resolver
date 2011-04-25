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
        'Moose'                       => '1.21',
        'Bio::Chado::Schema'          => '0.058',
        'MooseX::Role::Parameterized' => '0.23',
        'YAML::XS'                    => '0.34',
        'Plack'                       => '0.9963',
        'Module::Versions'            => '0.02',
        'FCGI::Engine'                => '0.18',
        'MooseX::NonMoose'            => '0.17'
    },
    recommends     => { 'DBD::Oracle' => '1.27'},
    add_to_cleanup => [' Resolver- *'],
);

$builder->create_build_script();

1;
