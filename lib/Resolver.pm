package Resolver;

use strict;
use Bio::Chado::Schema;
use File::Spec::Functions;
use Moose;
use Resolver::Config::Yaml;
use namespace::autoclean;
use Carp::Always;
use CHI;
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
    isa => 'Bio::Chado::Schema',
    is  => 'rw'
);

has 'legacy_model' => (
    isa       => 'Bio::Chado::Schema',
    is        => 'rw',
    predicate => 'has_legacy_model'
);

has 'cache' => (
	is => 'rw', 
	isa => 'Object', 
	lazy_build => 1
);

sub _build_cache {
	my $self = shift;
	my $config = $self->config;
	CHI->new(
		driver => $config->cache->driver, 
		servers => [ $config->cache->servers], 
		namespace => $config->cache->namespace, 
		expires_in => '6 days'
	);
}

# This method will run once at server start
sub startup {
    my $self = shift;

    #default log level
    $self->log->level( $ENV{MOJO_DEBUG} ? $ENV{MOJO_DEBUG} : 'debug' );
    $self->connect_to_db;

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

sub connect_to_db {
    my $self     = shift;
    my $database = $self->config->database;
    my $opt      = $database->meta->has_attribute('opt')
        ? $database->opt
            : {};
            my $schema = Bio::Chado::Schema->connect(
                $database->dsn, $database->user,
                $database->pass, { $opt => 1 }
            );
            my $source = $schema->source('Sequence::Feature');
            $source->add_column(
                is_deleted => {
                    data_type     => 'boolean',
                    default_value => 'false',
                    is_nullable   => 0,
                    size          => 1
                }
            );
            $self->model($schema);

    #additional database connection if any through module option
    #my $module = $self->module_config;
    #if ( defined $module->{option}->{database} ) {
    #    my $db_conf = $module->{option}->{database};
    #    my $legacy_schema
    #        = Bio::Chado::Schema->connect( $db_conf->{dsn}, $db_conf->{user},
    #        $db_conf->{pass},
    #        $db_conf->{opt} ? { $db_conf->{opt} => 1 } : {} );

            #adding attribute at runtime
            #my $meta = __PACKAGE__->meta;
            #$meta->add_attribute(
            #    'legacy_model',
            #    (   isa => 'Bio::Chado::Schema',
            #        is  => 'rw'
            #    )
            #);
            #$self->legacy_model($legacy_schema);
            #}
    }

    1;
