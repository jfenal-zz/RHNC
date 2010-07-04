package RHNC::System::CustomInfo;

use warnings;
use strict;
use Params::Validate;
use Data::Dumper;
use Carp;
use base qw( RHNC );

=head1 NAME

RHNC::System::CustomInfo - Red Hat Network Client - Systems handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::System::CustomInfo;

    my $foo = RHNC::System::CustomInfo->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 is_systemid

Returns true if system id B<looks> valid, false otherwise

=cut

sub is_systemid {
    my ($s) = shift;
    return 1 if $s =~ m{ \A \d+ \z }imxs;
    return 0;
}

my %properties = (
    rhnc          => [ 1, undef, undef, undef ],
    id            => [ 0, undef, undef, undef ],
    label         => [ 0, undef, undef, undef ],
    name          => [ 1, undef, undef, undef ],
    description   => [ 1, undef, undef, undef ],
    system_count  => [ 0, undef, undef, undef ],
    last_modified => [ 0, undef, undef, undef ],
);

=head2 new

Create a new RHNC::System::CustomInfo class. 

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    bless $self, $class;

    my %v = map { $_ => 0 } ( keys %properties );

    #    $self->_setdefaults();
    my %p = validate( @args, \%v );

    # Parameters standardization
    if ( defined $p{name} && !defined $p{label} ) {
        $p{label} = $p{name};
        delete $p{name};
    }

    # populate object from either @args or
    # default
    for my $i ( keys %properties ) {
        if ( defined $p{$i} ) {
            $self->{$i} = $p{$i};
        }
    }

    return $self;
}

=head2 create

Create a new RHNC::System::CustomInfo class, and persist it. 

=cut

sub create {
    my ( $self, @args ) = @_;

    if ( !ref $self ) {
        $self = __PACKAGE__->new(@args);

    }

    my $res =
      $self->{rhnc}->call( 'system.custominfo.createKey', $self->{label},
        $self->{description} );

    return $self;
}

=head2 list

Return a hash of systems by id (keys being id, name, last_checkin).

    $system_ref = RHNC::System::CustomInfo->list;

=cut

sub list {
    my ( $self, @p ) = @_;
    my ($rhnc);

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->list_systems
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::list_systems($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->list_systems($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }

    my $list = $rhnc->call('system.customeinfo.listAllKeys');

    my $keys;
    foreach my $s (@$list) {
        push @$keys, __PACKAGE__->new( $rhnc, %$s );
    }

    return $keys;
}

=head2 id

Return system's id.

  $id = $s->id;

=cut

sub id {
    my ( $self, @args ) = @_;
    my $rhnc;

    if ( ref $self eq __PACKAGE__ ) {

        return $self->{id};
    }
    elsif ( $self eq __PACKAGE__ ) {
        $rhnc = shift @args;
        my $system = shift @args;
        $self = __PACKAGE__->get( $rhnc, $system );
        return $self->{id};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {
        my $rhnc   = $self;
        my $system = shift @args;
        $self = __PACKAGE__->get( $rhnc, $system );
        return $self->{id};
    }

    return;
}

=head2 label

Return custom info key label.

  $label = $cik->label;

=cut

sub label {
    my ( $self, @args ) = @_;

    if ( !defined $self->{label} && defined $self->{name} ) {
        $self->{label} = $self->{name};
    }

    return $self->{label};
}

=head2 name

Return custom info key name (label).

  $name = $cik->name;

=cut

sub name {
    my ( $self, @args ) = @_;

    if ( !defined $self->{name} && defined $self->{label} ) {
        $self->{name} = $self->{label};
    }

    return $self->{name};
}

=head2 get

Get a custom info key label details.

  $ci = RHNC::System::CustomInfo::get( $RHNC, $name );
  $ci = RHNC::System::CustomInfo->get( $RHNC, $name );
  $ci = $oci->get( $name );

=cut

sub get {
    my ( $self, @p ) = @_;
    my ( $rhnc, $id_or_name );
    carp "not implemented yet";

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->list_systems
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::list_systems($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->list_systems($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }
    $id_or_name = shift @p;
    if ( $id_or_name !~ m{ \A \d+ \z }imxs ) {

        # we do not have an Id, let's search by name
        my $res = RHNC::System::CustomInfo->search( $rhnc, $id_or_name );
        $id_or_name = $res->{id};
    }
    my $res = $rhnc->call( 'system.getDetails', $id_or_name );

    $self = RHNC::System::CustomInfo->new(
        rhnc => $rhnc,
        name => $res->{name},
        id   => $res->{id},
        (
            defined $res->{last_checkin}
            ? ( last_checkin => $res->{last_checkin}->value() )
            : ()
        ),
    );

    return $self;
}

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn-session at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::System::CustomInfo


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

Copyright 2009,2010 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::System::CustomInfo
