package Resolver;

use strict;
use Bio::Chado::Schema;
use File::Spec::Functions;
use Moose;
use Resolver::Config::Yaml;
use namespace::autoclean;
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

# This method will run once at server start
sub startup {
    my $self = shift;

    # -- init config
    my $config = $self->config;

    # Routes
    my $r = $self->routes;
    $r->namespace('Resolver::Controller');

    $r->route('/id/:id')->to(
        controller => 'map',
        action     => 'resolve'
    );

}

1;
