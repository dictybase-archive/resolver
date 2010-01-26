package Resolver;

use strict;
use warnings;
use local::lib '/home/ubuntu/dictyBase/Libs/modern-perl';
use Bio::Chado::Schema;
use YAML qw/LoadFile/;
use File::Spec::Functions;
use Module::Find;
use Moose;
use Moose::Util;
extends 'Mojolicious';

has 'config' => (
    isa        => 'HashRef',
    is         => 'rw',
    lazy_build => 1,
);

sub _build_config {
    my $self = shift;

    my $file = catfile( $self->home->rel_dir('conf'), $self->mode . '.yaml' );
    if ( !-e $file ) {
        $self->log->debug("conf file $file does not exist");
        return;
    }

    #Load YAML file
    return LoadFile($file);
}

has 'model' => (
    isa => 'Bio::Chado::Schema',
    is  => 'rw'
);

has 'module_config' => (
    isa     => 'HashRef',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->config->{module};
    },
);

before 'module_config' => sub {
    my $self = shift;
    if ( !$self->config ) {
        $self->load_config;
    }
};

# This method will run once at server start
sub startup {
    my $self = shift;

    #default log level
    $self->log->level( $ENV{MOJO_DEBUG} ? $ENV{MOJO_DEBUG} : 'debug' );

    $self->connect_to_db;
    $self->inject_role;

    # Routes
    my $r = $self->routes;
    $r->namespace('Resolver::Controller');

    my $bridge = $r->bridge->to(
        controller => 'map',
        action     => 'validate'
    );
    $bridge->route('/id/:id')->to(
        controller => 'map',
        action     => 'map'
    );

}

sub inject_role {
    my $self = shift;

    my $module_conf = $self->module_config;
    my $role_namespace
        = defined $module_conf->{namespace}
        ? $module_conf->{namespace}
        : $self->home->app_class . '::Role';

    my $role_name = $role_namespace . '::' . $module_conf->{name};

    my $contrl_namespace = $self->home->app_class . '::Controller';
    my @controllers      = useall $contrl_namespace;

    #need to refactor this alias dynamically
    Moose::Util::apply_all_roles( $_->meta, ($role_name) ) for @controllers;
}

sub connect_to_db {
    my $self     = shift;
    my $database = $self->config->{database};
    my $schema
        = Bio::Chado::Schema->connect( $database->{dsn}, $database->{user},
        $database->{pass},
        $database->{opt} ? { $database->{opt} => 1 } : {} );
    $self->model($schema);

    #additional database connection if any through module option
    my $module = $self->module_config;
    if ( defined $module->{option}->{database} ) {
        my $db_conf = $module->{option}->{database};
        my $legacy_schema
            = Bio::Chado::Schema->connect( $db_conf->{dsn}, $db_conf->{user},
            $db_conf->{pass},
            $db_conf->{opt} ? { $db_conf->{opt} => 1 } : {} );

        #adding attribute at runtime
        my $meta = __PACKAGE__->meta;
        $meta->add_attribute(
            'legacy_model',
            (   isa => 'Bio::Chado::Schema',
                is  => 'rw'
            )
        );
        $self->legacy_model($legacy_schema);
    }
}

no Moose;

1;
