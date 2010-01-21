package Resolver::Role::DoesMultiGenome;

use warnings;
use strict;

use version; our $VERSION = qv('1.0.0');

# Other modules:
use List::MoreUtils qw/any/;
use Moose::Role;

# Module implementation

sub validate {
    my ( $self, $c ) = @_;
    my $app       = $self->app;
    my $model     = $app->model;
    my $id        = $c->stash('id');
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
        $c->res->code(404);
        $self->render( text => "Given id $id not found" );
        return;
    }

    my $type = $query_row->type->name;
    $self->app->log->debug("got type $type");
    if ( !$self->check_map($type) ) {
        $c->res->code(404);
        $self->render(
            text => "Sorry cannot resolve " . $type . ' and ' . $id );
        return;
    }
    $self->app->log->debug("It can map $type");

    $c->stash( type    => lc $type );
    $c->stash( feature => $query_row );
    return 1;
}

sub check_map {
    my ( $self, $type ) = @_;
    my $conf = $self->app->config;
    any {$type} @{ $conf->{resolve}->{types} };
}

sub map_to_url {
    my ($self,  $c)   = @_;
    my $id       = $self->context->stash('id');
    my $type     = $self->context->stash('type');
    my $base_url = $self->context->req->url->host;
    $base_url = $base_url ? 'http://'.$base_url. '/' : '/';

    $self->app->log->debug("got $id");
    $self->app->log->debug("got base $base_url");
    my $path = $self->$type($id);

    my $config = $self->app->config;

    #global prepend defined
    if ( defined $config->{resolve}->{prepend} ) {
        $path = $self->prepend . '/' . $path;

    }
    return $base_url . $path;
}

#this is kind of this role specific; kind of hard coded
sub prepend {
    my $self    = shift;
    my $context = $self->context;
    $context->stash('feature')->organism->species;
}

sub gene {
    my ( $self, $id ) = @_;
    $self->app->log->debug("got $id from gene");
    my $conf = $self->app->config;
    my $type = 'gene';
    my $prepend
        = $conf->{resolve}->{type}->{$type}->{prefix}
        ? $conf->{resolve}->{type}->{$type}->{prefix}
        : $type;
    return $prepend . '/' . $id;
}

sub transcript {
    my ( $self, $id ) = @_;
    my $conf = $self->app->config;
    my $type = $self->context->stash('type');
    my $prepend
        = $conf->{resolve}->{type}->{$type}->{prefix}
        ? $conf->{resolve}->{type}->{$type}->{prefix}
        : $type;
    my $feature = $self->context->stash('feature');
    my $gene    = $feature->search_related(
        'feat_relationship_subject_ids',
        { 'type.name' => 'part_of', },
        { join        => 'type' }
        )->search_related(
        'object',
        { 'type_2.name' => 'gene' },
        { join          => 'type', 'rows' => 1 }
        )->single;
    my $gene_url = $self->gene( $gene->dbxref->accession );
    return $gene_url . '/' . $prepend . '/' . $id;
}

sub est {
    my ( $self, $id ) = @_;
    my $config = $self->app->config;
    my $type = $self->context->stash('type');
    return 'db/cgi-bin?feature_pl?primary_id=' . $id
        if defined $config->{resolve}->{type}->{$type}->{noprefix};

    return $config->{resolve}->{type}->{$type}->{prefix}
        . '/db/cgi-bin?feature_pl?primary_id='
        . $id
        if defined $config->{resolve}->{type}->{$type}->{prefix};
}


sub polypeptide {
}

#
no Moose::Role;

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



