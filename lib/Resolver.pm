package Resolver;

use strict;
use warnings;
use local::lib '/home/ubuntu/dictyBase/Libs/modern-perl';
use Bio::Chado::Schema;
use YAML qw/LoadFile/;
use File::Spec::Functions;
use Module::Find;
use base 'Mojolicious';
#use Class::Trait qw/debug/; 

__PACKAGE__->attr('config');
__PACKAGE__->attr('model');

# This method will run once at server start
sub startup {
    my $self = shift;

    #default log level
    $self->log->level($ENV{MOJO_DEBUG} ? $ENV{MOJO_DEBUG}: 'debug');

    $self->load_config;
    $self->connect_to_db;
    #$self->inject_helper;

    # Routes
    my $r = $self->routes;
    my $bridge = $r->bridge->to(
    	controller => 'map', action => 'validate' 
    );
    $bridge->route('/id/:id')->to(
    	controller => 'map',  action => 'map'
    );

}

sub inject_helper {
	my $self = shift;
	my $helper_namespace = $self->home->app_class . '::Helper';
	$self->log->debug(join ("\n",  findallmod $helper_namespace),  "\n");
	Class::Trait->apply('Resolver::Map',  findallmod $helper_namespace);
	Class::Trait->initialize;
}

sub load_config {
	my $self = shift;

	my $file = catfile($self->home->rel_dir('conf'), $self->mode.'.yaml');
	if (!-e $file) {
		$self->log->debug("conf file $file does not exist");
		return;
	}
	#Load YAML file
	$self->config(LoadFile($file));
}

sub connect_to_db {
	my $self = shift;
	my $database = $self->config->{database};
	my $schema = Bio::Chado::Schema->connect(
		$database->{dsn}, 
		$database->{user}, 
		$database->{pass}, 
		$database->{opt} ? { $database->{opt} => 1} : {}
	);
	$self->model($schema);
} 

1;
