package Resolver;

use strict;
use warnings;
use local::lib '/home/ubuntu/dictyBase/Libs/modern-perl';
use Bio::Chado::Schema;
use YAML qw/LoadFile/;
use File::Spec::Functions;
use Module::Find;
use Moose::Util;
use base 'Mojolicious';

__PACKAGE__->attr('config');
__PACKAGE__->attr('model');

# This method will run once at server start
sub startup {
    my $self = shift;

    #default log level
    $self->log->level($ENV{MOJO_DEBUG} ? $ENV{MOJO_DEBUG}: 'debug');

    $self->load_config;
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
    my $self             = shift;
    my $role_namespace   = $self->home->app_class . '::Role';
    my $contrl_namespace = $self->home->app_class . '::Controller';
    my @controllers      = useall $contrl_namespace;
    Moose::Util::apply_all_roles(
        $_->meta,
        findallmod($role_namespace),
        {   -alias => {
                transcript => 'rrna',
                transcript => 'trna',
                transcript => 'mrna',
                est        => 'chromosome',
                est        => 'contig',
                est        => 'supercontig'
            }
        }
    ) for @controllers;
}

sub load_config {
    my $self = shift;

    my $file = catfile( $self->home->rel_dir('conf'), $self->mode . '.yaml' );
    if ( !-e $file ) {
        $self->log->debug("conf file $file does not exist");
        return;
    }

    #Load YAML file
    $self->config( LoadFile($file) );
}

sub connect_to_db {
    my $self     = shift;
    my $database = $self->config->{database};
    my $schema
        = Bio::Chado::Schema->connect( $database->{dsn}, $database->{user},
        $database->{pass},
        $database->{opt} ? { $database->{opt} => 1 } : {} );
    $self->model($schema);
}

1;
