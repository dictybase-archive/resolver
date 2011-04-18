package Resolver::Role::DoesMultiGenomeLegacy;

# Other modules:
use List::MoreUtils qw/any/;
use Moose::Role;
use MooseX::Aliases;
use Bio::Chado::Schema;
use namespace::autoclean;

# Module implementation

has 'is_legacy' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    handles => {
        legacy        => 'set',
        unset_legacy  => 'unset',
        toggle_legacy => 'toggle',
        not_legacy    => 'not'
    },
);

sub revalidate {
    my ( $self) = @_;
    my $app         = $self->app;
    my $id          = $self->stash('id');
    my $mapper_name = $self->stash('mapper_name');
    my $model;
    if ( $self->check_legacy_id($id) ) {
        if ( !$app->has_legacy_model ) {
            my $legacy_conf = $app->config->mapper->$mapper_name->option->database;
            my $opt
                = $legacy_conf->meta->has_attribute('opt')
                ? $legacy_conf->opt
                : {};
            $model = Bio::Chado::Schema->connect(
                $legacy_conf->dsn, $legacy_conf->user,
                $legacy_conf->pass, { $opt => 1 }
            );
            my $source = $model->source('Sequence::Feature');
            $source->add_column(
                is_deleted => {
                    data_type     => 'boolean',
                    default_value => 'false',
                    is_nullable   => 0,
                    size          => 1
                }
            );

            $app->legacy_model($model);
        }
        else {
            $model = $app->legacy_model;
        }
    }
    else {
        $model = $app->model;
    }

    my $query_row = $model->resultset('Sequence::Feature')->find(
        {   'is_deleted'       => 0,
            'dbxref.accession' => $id,
        },
        {   join     => [qw/dbxref organism/],
            prefetch => [qw/type/],
            select   => [
                'feature_id',           'type_id',
                'organism_id',          'organism.species',
                'organism.organism_id', 'organism.genus'
            ],
        }
    );

    if ( !$query_row ) {
        $self->res->code(404);
        $self->render( text => "Given id $id not found" );
        return;
    }

    my $type = $query_row->type->name;
    $self->app->log->debug("got type $type");
    if ( !$self->check_map( $type, $mapper_name ) ) {
        $self->res->code(404);
        $self->render(
            text => "Sorry cannot resolve " . $type . ' and ' . $id );
        return;
    }
    $self->app->log->debug("It can map $type");

    $self->stash( type => lc $type );
    $self->stash(
        run_type => $self->is_legacy
        ? 'legacy_' . lc $type
        : lc $type
    );
    $self->stash( feature => $query_row );
    $self->stash( species => $query_row->organism->species );
    return 1;
}

sub check_legacy_id {
    my ( $self, $id ) = @_;
    if ( $id =~ /^DDB\w{0,2}\d+$/ ) {
        $self->legacy;
        $self->is_legacy;
    }
}

sub check_map {
    my ( $self, $type, $mapper_name ) = @_;
    my $resolve = $self->app->config->mapper->$mapper_name->resolve;
    any {$type} $resolve->get_all_types;
}

sub map_to_url {
    my ( $self) = @_;
    $self->revalidate;

    my $id       = $self->stash('id');
    my $type     = $self->stash('type');
    my $run_type = $self->stash('run_type');
    my $base_url = $self->req->url->host;

    my $config      = $self->app->config;
    my $mapper_name = $self->stash('mapper_name');
    my $mapper      = $config->mapper->$mapper_name;

    $base_url = $base_url ? 'http://' . $base_url . '/' : '/';

    $self->app->log->debug("got $id");
    $self->app->log->debug("got base $base_url");
    $self->app->log->debug("got run type $run_type");
    my $path = $self->$run_type( $id, $mapper_name );

    #global prepend defined
    if ( $mapper->meta->has_attribute('prepend') ) {
        if ( !$mapper->type->meta->has_attribute($type) ) {
            $path = $self->prepend . '/' . $path;
        }
        elsif (!$mapper->type->$type->meta->has_attribute('nospecies') ) {
            $path = $self->prepend . '/' . $path;
        }
    }
    return $base_url . $path;
}

#this is kind of this role specific; kind of hard coded
sub prepend {
    my ( $self ) = @_;
    return $self->stash('species');
}

sub gene {
    my ( $self, $id, $mapper_name ) = @_;
    $self->app->log->debug("got $id from gene");
    my $mapper = $self->app->config->mapper->$mapper_name;
    my $type   = 'gene';
    my $prepend;
    if (    $mapper->type->meta->has_attribute($type)
        and $mapper->type->$type->meta->has_attribute('prefix') )
    {
        $prepend = $mapper->type->$type->prefix;
    }
    else {
        $prepend = $type;
    }
    return $prepend . '/' . $id;
}

sub transcript {
    my ( $self, $id, $mapper_name ) = @_;
    my $mapper = $self->app->config->mapper->$mapper_name;
    my $type   = $self->stash('type');
    my $prepend
        = $mapper->type->$type->meta->has_attribute('prefix')
        ? $mapper->type->$type->prefix
        : $type;
    my $feature = $self->stash('feature');
    my $gene    = $feature->search_related(
        'feature_relationship_subjects',
        { 'type.name' => 'part_of', },
        { join        => 'type' }
        )->search_related(
        'object',
        { 'type_2.name' => 'gene' },
        { join          => 'type', 'rows' => 1 }
        )->single;
    my $gene_url = $self->gene( $gene->dbxref->accession, $mapper_name );
    return $gene_url . '/' . $prepend . '/' . $id;
}

sub legacy_est {
    my ( $self, $id, $mapper_name ) = @_;
    my $type    = $self->stash('type');
    my $species = $self->stash('species');
    return $species . '/db/cgi-bin/feature_page.pl?primary_id=' . $id;
}

sub est {
    my ( $self, $id ) = @_;
    my $type = $self->stash('type');
    return 'db/cgi-bin/feature_page.pl?primary_id=' . $id;
}

sub polypeptide {
}

alias rrna              => 'transcript';
alias trna              => 'transcript';
alias mrna              => 'transcript';
alias legacy_gene       => 'gene';
alias legacy_rrna       => 'transcript';
alias legacy_mrna       => 'transcript';
alias legacy_trna       => 'transcript';
alias chromosome        => 'est';
alias contig            => 'est';
alias supercontig       => 'est';
alias legacy_chromosome => 'legacy_est';
alias legacy_contig     => 'legacy_est';

#

1;    # Magic true value required at end of module

__END__

=head1 NAME

<MODULE NAME> - [One line description of module's purpose here]


=head1 VERSION

This document describes <MODULE NAME> version 0.0.1


=head1 SYNOPSIS

use <MODULE NAME>;

=for author to fill in:
Brief code example(s) here showing commonest usage(s).
This section will be as far as many users bother reading
so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
Write a full description of the module and its features here.
Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
Write a separate section listing the public components of the modules
interface. These normally consist of either subroutines that may be
exported, or methods that may be called on objects belonging to the
classes provided by the module.

=head2 <METHOD NAME>

=over

=item B<Use:> <Usage>

[Detail text here]

=item B<Functions:> [What id does]

[Details if neccessary]

=item B<Return:> [Return type of value]

[Details]

=item B<Args:> [Arguments passed]

[Details]

=back

=head2 <METHOD NAME>

=over

=item B<Use:> <Usage>

[Detail text here]

=item B<Functions:> [What id does]

[Details if neccessary]

=item B<Return:> [Return type of value]

[Details]

=item B<Args:> [Arguments passed]

[Details]

=back


=head1 DIAGNOSTICS

=for author to fill in:
List every single error and warning message that the module can
generate (even the ones that will "never happen"), with a full
explanation of each problem, one or more likely causes, and any
suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
A full explanation of any configuration system(s) used by the
module, including the names and locations of any configuration
files, and the meaning of any environment variables or properties
that can be set. These descriptions must also include details of any
configuration language used.

<MODULE NAME> requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
A list of all the other modules that this module relies upon,
  including any restrictions on versions, and an indication whether
  the module is part of the standard Perl distribution, part of the
  module's distribution, or must be installed separately. ]

  None.


  =head1 INCOMPATIBILITIES

  =for author to fill in:
  A list of any modules that this module cannot be used in conjunction
  with. This may be due to name conflicts in the interface, or
  competition for system or program resources, or due to internal
  limitations of Perl (for example, many modules that use source code
		  filters are mutually incompatible).

  None reported.


  =head1 BUGS AND LIMITATIONS

  =for author to fill in:
  A list of known problems with the module, together with some
  indication Whether they are likely to be fixed in an upcoming
  release. Also a list of restrictions on the features the module
  does provide: data types that cannot be handled, performance issues
  and the circumstances in which they may arise, practical
  limitations on the size of data sets, special cases that are not
  (yet) handled, etc.

  No bugs have been reported.Please report any bugs or feature requests to
  dictybase@northwestern.edu



  =head1 TODO

  =over

  =item *

  [Write stuff here]

  =item *

  [Write stuff here]

  =back


  =head1 AUTHOR

  I<Siddhartha Basu>  B<siddhartha-basu@northwestern.edu>


  =head1 LICENCE AND COPYRIGHT

  Copyright (c) B<2003>, Siddhartha Basu C<<siddhartha-basu@northwestern.edu>>. All rights reserved.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself. See L<perlartistic>.


  =head1 DISCLAIMER OF WARRANTY

  BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
  FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
  OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
  PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
  EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
  ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
  YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
  NECESSARY SERVICING, REPAIR, OR CORRECTION.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
  WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
  REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
  LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
  OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
  THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
		  RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
		  FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
  SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGES.



