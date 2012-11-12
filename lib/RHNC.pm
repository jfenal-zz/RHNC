package RHNC;

use warnings;
use strict;
use Exporter qw( import );
our @ISA = qw(Exporter);

our @EXPORT = qw( &entitlement_exists &entitlements &_unique
    &_intersect &_array_diff &_array_minus &_get_self_rhnc_args);

use Params::Validate;
use Carp;

use vars qw(  %_properties %entitlement_exists );

use Frontier::Client;
use RHNC::Session;
use RHNC::ActivationKey;
use RHNC::Errata;
use RHNC::Kickstart;
use RHNC::KickstartTree;
use RHNC::Org;
use RHNC::Package;
use RHNC::Schedule;
use RHNC::System;
use RHNC::SystemGroup;
use RHNC::Channel;
use RHNC::ConfigChannel;
use RHNC::System::CustomInfo;

our $_xmlfalse = Frontier::RPC2::Boolean->new(0);
our $_xmltrue  = Frontier::RPC2::Boolean->new(1);
our %_rhnc_for;

our %entitlement = (
    m             => 'monitoring_entitled',
    monitoring    => 'monitoring_entitled',
    p             => 'provisioning_entitled',
    provisioning  => 'provisioning_entitled',
    vp            => 'virtualization_host_platform',
    virt_platform => 'virtualization_host_platform',
    v             => 'virtualization_host',
    virt          => 'virtualization_host',
);

our @EXPORTS = qw( $VERSION $_xmlfalse $_xmltrue );

=head1 NAME

RHNC - An OO Red Hat Network Satellite Client.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC;

    my $foo = RHNC->new();
    ...

=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=cut

sub _bool {
    my ($arg) = @_;

    return $arg ? $_xmltrue : $_xmlfalse;
}

=head2 new

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 manage($object)

Manage C<$object> using RHNC. Allows persistance of such objects, if
not already created.

$object must be blessed in 'RHNC::*' namespace.

=cut

sub manage {
    my ( $self, $object ) = @_;

    if ( !defined $object ) {
        croak 'Can\'t manage undefined object';
    }
    if ( ref $object !~ m{ \A RHNC:: }imxs ) {
        carp 'Can\'t manage this class of objects : ' . ref $object;
        return;
    }

    $object->{rhnc} = $self;
    $object->{_session} = $self->session;

    my $uid = $object->_uniqueid;
    if ( !defined $uid || $uid eq q{} ) {
        croak 'Object unique id not defined';
    }

    $self->{_managed}{ref $object}{$uid} = \$object;

    return $self;
}

=head2 unmanage( $obj )

Remove a specified object from list of managed object. Remove cross
references.

=cut

sub unmanage {
    my ( $self, $object ) = @_;

    if ( ref $object !~ m{ \A RHN:: }imxs ) {
        return;
    }

    delete $self->{_managed}{ref $object}{ $object->_uniqueid() };
    delete $object->{_session};

    return $self;
}

=head2 save()

Save all unsaved objects

=cut

sub save {
    my ($self) = @_;

    foreach my $o ( keys %{ $self->{_managed} } ) {
        $o->save();
    }

    return $self;
}

=head2 rhnc()

Return corresponding RHN Client, if available.

  $session = $o->rhnc(); 
  $session = RHNC->rhnc(); 
  $session = RHNC::rhnc();
  $session = RHNC::rhnc();

=cut

sub rhnc {
    my ( $self, $rhnc ) = @_;

    if ( defined $rhnc ) {
        $self->{rhnc} = $rhnc;
    }
    return $self->{rhnc} if defined $self->{rhnc};

    return;
}

=head2 entitlements

Return an array ref for possible entitlements.

=cut

my $entitlement_arrayref;

sub entitlements {
    if ( !defined $entitlement_arrayref ) {
        my %e = map { $_ => 1 } values %entitlement;
        $entitlement_arrayref = [ keys %e ];
    }
    return $entitlement_arrayref;
}

=head2 entitlement_exists

Return true if the entitlement exists, false otherwise.

=cut

my %entitlement_exists;

BEGIN {
    %entitlement_exists = map { $_ => 1 } @{ entitlements() };
}

sub entitlement_exists {
    my ($e) = @_;
    if ( !defined $entitlement_exists{$e} ) {
    }
    return 1 if defined $entitlement_exists{$e};
    return 0;
}

1;

# Not shipped in RHEL... :( 
# taken from Array::Utils by Sergei A. Fedorov

sub _unique(@) {
    return keys %{ { map { $_ => undef } @_ } };
}

sub _intersect(\@\@) {
    my %e = map { $_ => undef } @{ $_[0] };
    return grep { exists( $e{$_} ) } @{ $_[1] };
}

sub _array_diff(\@\@) {
    my %e = map { $_ => undef } @{ $_[1] };
    return @{
        [
            ( grep { ( exists $e{$_} ) ? ( delete $e{$_} ) : (1) } @{ $_[0] } ),
            keys %e
        ]
      };
}

sub _array_minus(\@\@) {
    my %e = map { $_ => undef } @{ $_[1] };
    return grep( !exists( $e{$_} ), @{ $_[0] } );
}

#
# _get_self_rhnc_args
#
# Do the heavy lifting to get $rhnc and remaining args for class methods
#
# ($rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_);
#
sub _get_self_rhnc_args {
    my ( $package, $self, @args ) = @_;
    my $rhnc;

    if ( ref $self eq $package && defined $self->{rhnc} ) {

        # OO context, eg $ch->list_systems
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as __PACKAGE__::list_systems($rhnc)
        $rhnc = $self;
    }
    elsif ( defined $self && $self eq $package && ref( $args[0] ) eq 'RHNC::Session' ) {

        # Called as __PACKAGE__->list_systems($rhnc)
        $rhnc = shift @args;
    }
    else {
        croak "No RHNC client given here";
    }

    return ( $self, $rhnc, @args );
}

=head1 DIAGNOSTICS



=head1 CONFIGURATION AND ENVIRONMENT

This program relies on the existance of a configuration file, either
F</etc/satellite_api.conf> or F<$HOME/.rhnrc>.

This file (in INI format) should contain three directives in the
C<[rhn]> section:

  [rhn]
  host=satellite.example.com
  user=rhn-admin
  password=s3cr3t

Both files can exist, information in  F<$HOME/.rhnrc> will take
precedence.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 AUTHOR

Jerome Fenal, C<< <jfenal at free.fr> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC


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


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Jerome Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC
