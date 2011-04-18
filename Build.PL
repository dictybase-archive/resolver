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
        'Mojolicious'                 => '0.999938',
        'Moose'                       => '1.21',
        'Bio::Chado::Schema'          => '0.058',
        'MooseX::Role::Parameterized' => '0.23',
        'CHI'                         => '0.36',
        'Cache::Memcached::Fast'      => '0.19',
        'YAML::LibYAML'               => '0.32',
        'Plack'                       => '0.9941',
        'Module::Versions'            => '0.02',
        'FCGI::Engine'                => '0.16',
        'Mojolicious::Plugin::Bundle' => '0.001',
        'Mojolicious::Plugin::Cache'  => '0.0011',
    },
    add_to_cleanup => ['Resolver-*'],
);

$builder->create_build_script();

1;
