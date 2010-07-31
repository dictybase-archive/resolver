package Resolver;

use strict;
use Bio::Chado::Schema;
use File::Spec::Functions;
use Moose;
use Resolver::Config::Yaml;
use namespace::autoclean;
use Carp::Always;
use CHI;
use Carp::Always;
extends 'Mojolicious';

has 'config' => (
    isa        => 'Resolver::Config::Yaml',
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
    Resolver::Config::Yaml->new->load($file);
}

has 'model' => (
    isa        => 'Bio::Chado::Schema',
    is         => 'rw',
    lazy_build => 1
);

sub _build_model {
    my $self     = shift;
    my $database = $self->config->database;
    my $opt
        = $database->meta->has_attribute('opt')
        ? $database->opt
        : {};
    my $schema = Bio::Chado::Schema->connect( $database->dsn, $database->user,
        $database->pass, { $opt => 1 } );
    my $source = $schema->source('Sequence::Feature');
    $source->add_column(
        is_deleted => {
            data_type     => 'boolean',
            default_value => 'false',
            is_nullable   => 0,
            size          => 1
        }
    );
    return $schema;
}

has 'legacy_model' => (
    isa       => 'Bio::Chado::Schema',
    is        => 'rw',
    predicate => 'has_legacy_model'
);

has 'cache' => (
    is         => 'rw',
    isa        => 'Object',
    lazy_build => 1
);

sub _build_cache {
    my $self   = shift;
    my $config = $self->config;
    CHI->new(
        driver     => $config->cache->driver,
        servers    => [ $config->cache->servers ],
        namespace  => $config->cache->namespace,
        expires_in => '6 days'
    );
}

# This method will run once at server start
sub startup {
    my $self = shift;

    #default log level
    $self->log->level( $ENV{MOJO_DEBUG} ? $ENV{MOJO_DEBUG} : 'debug' );
    #$self->connect_to_db;

    # Routes
    my $r = $self->routes;
    $r->namespace('Resolver::Controller');

    my $bridge = $r->bridge->to(
        controller => 'input',
        action     => 'validate'
    );
    $bridge->route('/id/:id')->to(
        controller => 'map',
        action     => 'resolve'
    );

}


1;
