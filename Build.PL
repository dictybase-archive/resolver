#!/usr/bin/perl -w
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name  => 'Resolver',
    license      => 'perl',
    dist_author  => 'Siddhartha Basu <siddhartha-basu@northwestern.edu>',
    dist_abstract => 'Module for resolving Ids', 
    dist_version => '0.1',
    requires     => {
        'Mojo'          => '0.991244',
        'Apache2::Mojo' => '0.0047', 
        'YAML' => '', 
        'Moose' => '1.09', 
        'Bio::Chado::Schema' => '0.05703', 
        'MooseX::Role::Parameterized' => '0.19'
    },
    build_requires => {
    	 'Archive::Extract' => '',
    	
		},
    add_to_cleanup => ['Resolver-*'],
    create_readme  => 1,
);

$builder->create_build_script();


1;
