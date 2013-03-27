package Resolver::Role::DoesExternal;

# Other modules:
use Moose::Role;
use namespace::autoclean;

sub map_to_url {
   my ( $self) = @_;
   my $id       = $self->stash('id');
   my $mapper_name = $self->stash('mapper_name');
   my $path = $self->app->config->mapper->$mapper_name->option->url;
   my $url = $path->base.$id.$path->part;
   return $url;
}

1;

#Magic true value required at end of module


