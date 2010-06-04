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
    id                 => [ 0, undef, undef, undef ],
    profile_name       => [ 1, undef, undef, undef ],
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
);

=head2 new

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    bless $self, $class;

    my %v = map { $_ => 0 } ( keys %properties );

#    $self->_setdefaults();
    my %p = validate( @args, \%v );

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

Return a list of systems by id

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

=cut

sub id {
    my ( $self, @args ) = @_;

    return $self->{id};
}


=head2 last_checkin

Return system's last_checkin

=cut

sub last_checkin {
    my ( $self, @args ) = @_;

    return $self->{last_checkin};
}

=head2 get

Get a system by profile name 

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

    my $r = $rhnc->call( 'system.getDetails', $id_or_name );

print Dumper $r;

    $self = RHNC::System->new();
    
    

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
