package Resolver::Controller::Map;

# Other modules:
use Moose;
use Moose::Util qw/apply_all_roles/;
use namespace::autoclean;
extends 'Resolver::Controller::Input';

# Module implementation
#

sub resolve {
    my ($self) = @_;
    if ( !$self->validate ) {
        $self->app->log->debug("matches false");
        $self->res->code(404);
        $self->render(
            text => "Given id " . $self->stash('id') . " cannot be mapped" );
        return;
    }

    my $url;
    my $mapper_name = $self->stash('mapper_name');
    my $role        = 'Resolver::Role::'
        . $self->app->config->mapper->$mapper_name->module;
    apply_all_roles( $self, $role );

    $self->app->log->debug("applied $role");
    $url = $self->map_to_url;
    $self->app->log->debug("got url $url from db");
    $self->redirect_to($url);
}

1;    # Magic true value required at end of module

