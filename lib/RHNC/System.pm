package RHNC::System;

use warnings;
use strict;
use Params::Validate;
use Data::Dumper;
use Carp;
use base qw( RHNC );

=head1 NAME

RHNC::System - Red Hat Network Client - Systems handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::System;

    my $foo = RHNC::System->new();
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

#
# Valid properties for a RHNC::System
#
#    * int "id" - System id
#    * string "profile_name"
#    * string "base_entitlement" - System's base entitlement label.
#      (enterprise_entitled or sw_mgr_entitled)
#    * array "string"
#          o addon_entitlements System's addon entitlements labels,
#            including monitoring_entitled, provisioning_entitled,
#            virtualization_host, virtualization_host_platform * boolean
#            "auto_update" - True if system has auto errata updates enabled.
#    * string "release" - The Operating System release (i.e. 4AS, 5Server
#    * string "address1"
#    * string "address2"
#    * string "city"
#    * string "state"
#    * string "country"
#    * string "building"
#    * string "room"
#    * string "rack"
#    * string "description"
#    * string "hostname"
#    * string "osa_status" - Either 'unknown', 'offline', or 'online'.
#    * boolean "lock_status" - True indicates that the system is
#              locked. False indicates that the system is unlocked.
#

my %properties = (
    rhnc              => [ 1, undef, undef, undef ],
    id                 => [ 0, undef, undef, undef ],
    name               => [ 1, undef, undef, undef ],
    profile_name       => [ 0, undef, undef, undef ],
    base_entitlement   => [ 1, undef, undef, undef ],
    addon_entitlements => [ 1, undef, undef, undef ],
    auto_update        => [ 0, undef, undef, undef ],
    release            => [ 0, undef, undef, undef ],
    address1           => [ 0, undef, undef, undef ],
    address2           => [ 0, undef, undef, undef ],
    city               => [ 0, undef, undef, undef ],
    state              => [ 0, undef, undef, undef ],
    country            => [ 0, undef, undef, undef ],
    building           => [ 0, undef, undef, undef ],
    room               => [ 0, undef, undef, undef ],
    rack               => [ 0, undef, undef, undef ],
    description        => [ 0, undef, undef, undef ],
    hostname           => [ 0, undef, undef, undef ],
    osa_status         => [ 0, undef, undef, undef ],
    lock_status        => [ 0, undef, undef, undef ],
    last_checkin       => [ 0, undef, undef, undef ],
);

=head2 new

Create a new RHNC::System class. 

B<BEWARE>: One should not need to create a new one, besides B<get>ting
it from Satellite directly.

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
    if (defined $p{profile_name} && ! defined $p{name} ) {
        $p{name} = $p{profile_name};
        delete $p{profile_name};
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

=head2 list

Return a hash of systems by id (keys being id, name, last_checkin).

    $system_ref = RHNC::System->list;

=cut

sub list {
    my ( $self, @p ) = @_;
    my ( $rhnc, $pattern );

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

    $pattern = shift @p;

    my $list;
    if ( defined $pattern ) {
        $list = $rhnc->call( 'system.searchByName', $pattern );
    }
    else {
        $list = $rhnc->call('system.listSystems');
    }

    my %by_id;
    foreach my $s (@$list) {
        my $id = $s->{id};
        $by_id{$id}{id}           = $id;
        $by_id{$id}{name}         = $s->{name};
        $by_id{$id}{last_checkin} = $s->{last_checkin};
    }

    return \%by_id;
}

=head2 id

Return system's id.

  $id = $s->id;

=cut

sub id {
    my ( $self, @args ) = @_;
    my $rhnc;

    if ( ref $self eq __PACKAGE__ ) {
        print "Coucou 1\n";

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
    print "Coucou3\n";

    return;
}

=head2 last_checkin

Return system's last_checkin

  $lc = $s->last_checkin;

=cut

sub last_checkin {
    my ( $self, @args ) = @_;

    return $self->{last_checkin};
}

=head2 search

Get a system by profile name 

=cut

sub search {
    my ( $self, @p ) = @_;
    my ( $rhnc, $name );

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
    $name = shift @p;

    my $res = $rhnc->call( 'system.searchByName', $name );

    foreach my $s (@$res) {
        if ($s->{name} eq $name) {
            $self = RHNC::System->new( rhnc => $rhnc, %$s );
            return $self;
        }
    }
    return;
}

=head2 get

Get a system by profile id 

=cut

sub get {
    my ( $self, @p ) = @_;
    my ( $rhnc, $id_or_name );

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
        my $res = RHNC::System->search( $rhnc, $id_or_name );
        $id_or_name = $res->{id};
    }
    my $res = $rhnc->call( 'system.getDetails', $id_or_name );

    $self = RHNC::System->new( rhnc => $rhnc,  
        name => $res->{name},
        id => $res->{id},
        (defined $res->{last_checkin} ?( last_checkin =>
        $res->{last_checkin}->value() ) : () ),
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

    perldoc RHNC::System


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

1;    # End of RHNC::System
