package RHNC::SystemGroup;

use warnings;
use strict;
use Data::Dumper;
use Params::Validate;
use Carp;

use base qw( RHNC );

use vars qw( $AUTOLOAD %properties %valid_prefix );

=head1 NAME

RHNC::SystemGroup - Red Hat Network Client - SystemGroup handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::SystemGroup;

    my $foo = RHNC::SystemGroup->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=cut

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %valid_prefix = map { $_ => 1 } qw( Dr. Hr. Miss
  Mr. Mrs. Sr. );
my %properties = (
    id           => [ 0, undef, undef, undef ],
    name         => [ 1, undef, undef, undef ],
    description  => [ 1, undef, undef, undef ],
    org_id       => [ 0, undef, undef, undef ],
    system_count => [ 0, undef, undef, undef ],
    rhnc         => [ 0, undef, undef, undef ],
);

=head2 new

Create a new system group.

  $sg = RHNC::SystemGroup->new(
    rhnc        => $rhnc,
    name        => 'name',
    description => 'new group',
  );

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    bless $self, $class;

    my %v = map { $_ => 0 } ( keys %properties );

    my %p = validate( @args, \%v );

    for my $i ( keys %properties ) {
        $self->{$i} = $p{$i};
    }

    if (defined $self->{rhnc}) {
        $self->{rhnc}->manage($self);
    }

    return $self;
}

=head2 create

Persist system group, create it if needed.

  $sg = $sg->create();

=cut

sub create {
    my ( $self ) = @_;

    my $res = $self->{rhnc}->call( 'systemgroup.create', $self->{name}, $self->{description}, );

    return $self;
}

=head2 destroy

    $sg->destroy();

=cut
sub destroy {
    my ( $self, @args ) = @_;

    #   $self = ref($self) || $self;
    my $res = $self->{rhnc} ->call( 'systemgroup.delete', $self->{name} );
    return $res;
}


=head2 name

   my $name = $sg->name();

=cut

sub name {
    my ( $self, @args ) = @_;

    if ( defined $self->{name} ) {
        return $self->{name};
    }

    return;
}


=head2 id

   my $id = $sg->id();

=cut

sub id {
    my ( $self, @args ) = @_;

    return $self->{id};
}


=head2 description

   my $description = $sg->description();

=cut

sub description {
    my ( $self, @args ) = @_;

    return $self->{description};
}

=head2 org_id

   my $org_id = $sg->org_id();

=cut

sub org_id {
    my ( $self, @args ) = @_;

    return $self->{org_id};
}


=head2 system_count

   my $system_count = $sg->system_count();

=cut

sub system_count {
    my ( $self, @args ) = @_;

    return $self->{system_count};
}

=head2 add_servers

    my $rc = $sg->add_servers( @profile_names, @profile_ids,
    @RHNC::System );

=cut
sub add_servers {
    my ( $self, @args ) = @_;
    my @systems;
    while (my $s = shift @args) {
        if (ref $s eq 'ARRAY') {
            push @systems, @{$s};
        }
        elsif (ref $s eq 'SCALAR') {
            push @systems, $s;
        }
        else {
            carp 'RHNC::SystemGroup::add_servers: should pass arrays or list of systems only, not ' . ref($s);
        }
    }

    my @system_id;
    foreach my $s ( @systems ) {
        if (RHNC::System::is_systemid( $s ) ) {
            push @system_id, $s;
        }
        elsif ( ref $s eq 'RHNC::System' ) {
            push @system_id, $s->id();
        }
        else {
            push @system_id, RHNC::System::id( $self->rhnc, $s);
        }
    }

    return;
}

=head2 remove_servers

    my $rc = $sg->remove_servers( @profile_names, @profile_ids );

=cut
sub remove_servers {

    carp 'not implemented yet !';
}


=head2 get

Get from Satellite a specific system group. Returns a RHNC::SystemGroup object.

By id: 

  $sg = RHNC::SystemGroup->get( $RHNC, $id );

By name:

  $sg = RHNC::SystemGroup->get( $RHNC, $id );

=cut

sub get {
    my ( $class, $rhnc, $sg_id_or_name) = @_;

    carp "No rhnc client given " if ref( $rhnc ) ne 'RHNC::Session';

    my $res = $rhnc->call('systemgroup.getDetails', $sg_id_or_name );
    my @list;

    my $sg = RHNC::SystemGroup->new(
        id           => $res->{id},
        name         => $res->{name},
        description  => $res->{description},
        org_id       => $res->{org_id},
        system_count => $res->{system_count},
    );
    $rhnc->manage($sg);

    return $sg;

}

=head2 list


Can work in OO context if you have already a SystemGroup at hand.

  @systemgroups = $systemgroup->list();

More likely in package context:

  @systemgroups = RHNC::SystemGroup->list( $RHNC );  # Need to specify a RHN client

=cut

sub list {
    my ( $self, $parm ) = @_;

    my $rhnc;
    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {    # OO context
        $rhnc = $self->{rhnc};
    }
    else {                # package context
        $rhnc = $parm;
    }

    my $res = $rhnc->call('systemgroup.listAllGroups');
    my @list;

    foreach my $g ( @$res ) {
        my $sg = __PACKAGE__->new(
            id           => $g->{id},
            name         => $g->{name},
            description  => $g->{description},
            org_id       => $g->{org_id},
            system_count => $g->{system_count},
        );
        $rhnc->manage($sg);
        push @list, $sg;
    }

    return @list;
}

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::SystemGroup


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RHNC-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RHNC-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RHNC-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/RHNC-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::SystemGroup
