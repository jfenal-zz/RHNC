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

None.
L<is_systemid> is to be referenced by its full name.

=head1 SUBROUTINES/METHODS

=head2 is_systemid

Returns true if system id B<looks> valid, false otherwise.

=cut

sub is_systemid {
    my ($s) = shift;
    return 1 if $s =~ m{ \A \d+ \z }imxs;
    return 0;
}

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
    rhnc               => [ 1, undef, undef, undef ],
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
    connection_path    => [ 0, undef, undef, undef ],
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
    if ( defined $p{profile_name} && !defined $p{name} ) {
        $p{name} = $p{profile_name};
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

    my $by_id = {};
    foreach my $s (@$list) {
        my $id = $s->{id};
        $by_id->{$id}{id}           = $id;
        $by_id->{$id}{name}         = $s->{name};
        $by_id->{$id}{last_checkin} = $s->{last_checkin};
    }

    return $by_id;
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

=head2 _uniqueid

Return system's _uniqueid (id)

  $lc = $s->_uniqueid;

=cut

sub _uniqueid {
    my ( $self, @args ) = @_;

    return $self->{id};
}

=head2 last_checkin

Return system's last_checkin

  $lc = $s->last_checkin;

=cut

sub last_checkin {
    my ( $self, @args ) = @_;

    return $self->{last_checkin};
}

=head2 profile_name      

Get or set a system profile name.

  $pname   = $sys->profile_name();
  $oldname = $sys->profile_name('newname.example.com');

=cut

sub profile_name {
    my ( $self, @args ) = @_;
    my $prev = $self->{profile_name};

    if ( scalar @args ) {
        my $profile_name = shift @args;
        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { profile_name => $profile_name } )
          or croak "Can't modify profile name to $self->{profile_name}";
        $self->{profile_name} = $profile_name;
        $self->{name}         = $profile_name;
    }

    return $prev;
}

=head2 base_entitlement  

Get or set the system's base_entitlement.
Will update this status directly in Satellite.

  $ent = $sys->base_entitlement;
  $sys->base_entitlement( 'enterprise_entitled' );
  $sys->base_entitlement( 'sw_mgr_entitled' );

=cut

sub base_entitlement {
    my ( $self, @args ) = @_;
    my $prev = $self->{base_entitlement};

    if (@args) {
        $self->{base_entitlement} = shift @args;
        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { base_entitlement => $self->{base_entitlement} } );
    }

    return $prev;
}

=head2 addon_entitlements

TODO

=cut

sub addon_entitlements {
    croak "Not implemented yet";
}

=head2 auto_update       

Get or set system's auto_update status.
Will update this status directly in Satellite.

  $status = $sys->auto_update;
  $sys->auto_update( 1 );   # enable
  $sys->auto_update( 0 );   # disable

=cut

sub auto_update {
    my ( $self, @args ) = @_;
    my $prev = $self->{auto_update}->value();

    if (@args) {
        $self->{auto_update} = shift @args;
        $self->{auto_update} = RHNC::_bool( $self->{auto_update} );

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { auto_errata_update => $self->{auto_update} } );
    }

    return $prev;
}

=head2 release           

Get system's release.

  $release = $sys->release;

=cut

sub release {
    my ($self) = @_;
    return $self->{release};
}

=head2 address1          

Get or set address1 attribute of a system.

  $a1 = $sys->address1;
  $sys->address1( 'new address' );

=cut

sub address1 {
    my ( $self, @args ) = @_;
    my $prev = $self->{address1};

    if (@args) {
        $self->{address1} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { address1 => $self->{address1} } );
    }

    return $prev;
}

=head2 address2          

Get or set address2 attribute of a system.

  $a1 = $sys->address2;
  $sys->address2( 'new address' );

=cut

sub address2 {
    my ( $self, @args ) = @_;
    my $prev = $self->{address2};

    if (@args) {
        $self->{address2} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { address2 => $self->{address2} } );
    }

    return $prev;
}

=head2 city          

Get or set city attribute of a system.

  $a1 = $sys->city;
  $sys->city( 'new address' );

=cut

sub city {
    my ( $self, @args ) = @_;
    my $prev = $self->{city};

    if (@args) {
        $self->{city} = shift @args;

        $self->{rhnc}
          ->call( 'system.setDetails', $self->{id}, { city => $self->{city} } );
    }

    return $prev;
}

=head2 state          

Get or set state attribute of a system.

  $a1 = $sys->state;
  $sys->state( 'new address' );

=cut

sub state {
    my ( $self, @args ) = @_;
    my $prev = $self->{state};

    if (@args) {
        $self->{state} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { state => $self->{state} } );
    }

    return $prev;
}

=head2 country          

Get or set country attribute of a system.

  $a1 = $sys->country;
  $sys->country( 'new address' );

=cut

sub country {
    my ( $self, @args ) = @_;
    my $prev = $self->{country};

    if (@args) {
        $self->{country} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { country => $self->{country} } );
    }

    return $prev;
}

=head2 building          

Get or set building attribute of a system.

  $a1 = $sys->building;
  $sys->building( 'new address' );

=cut

sub building {
    my ( $self, @args ) = @_;
    my $prev = $self->{building};

    if (@args) {
        $self->{building} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { building => $self->{building} } );
    }

    return $prev;
}

=head2 room          

Get or set room attribute of a system.

  $a1 = $sys->room;
  $sys->room( 'new address' );

=cut

sub room {
    my ( $self, @args ) = @_;
    my $prev = $self->{room};

    if (@args) {
        $self->{room} = shift @args;

        $self->{rhnc}
          ->call( 'system.setDetails', $self->{id}, { room => $self->{room} } );
    }

    return $prev;
}

=head2 rack          

Get or set rack attribute of a system.

  $a1 = $sys->rack;
  $sys->rack( 'new address' );

=cut

sub rack {
    my ( $self, @args ) = @_;
    my $prev = $self->{rack};

    if (@args) {
        $self->{rack} = shift @args;

        $self->{rhnc}
          ->call( 'system.setDetails', $self->{id}, { rack => $self->{rack} } );
    }

    return $prev;
}

=head2 description          

Get or set description attribute of a system.

  $a1 = $sys->description;
  $sys->description( 'new description' );

=cut

sub description {
    my ( $self, @args ) = @_;
    my $prev = $self->{description};

    if (@args) {
        $self->{description} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { description => $self->{description} } );
    }

    return $prev;
}

=head2 hostname          

Return system's hostname.

  $hostname = $sys->hostname;

=cut

sub hostname {
    my ($self) = @_;
    return $self->{hostname};
}

=head2 osa_status        

Return system's OSA status.

  $hostname = $sys->osa_status;

Returns one in C<qw( unknown offline online )>.

=cut

sub osa_status {
    my ($self) = @_;
    return $self->{osa_status};
}

=head2 lock_status       

Get or set a system's lock_status.

  $lock_status = $sys->lock_status;
  $sys->lock_status( 0 ); # unlock
  $sys->lock_status( 1 ); # lock

=cut

sub lock_status {
    my ( $self, @args ) = @_;
    my $prev = $self->{lock_status}->value();

    if (@args) {
        $self->{lock_status} = shift @args;
        $self->{lock_status} = RHNC::_bool( $self->{lock_status} );

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { lock_status => $self->{lock_status} } );
    }

    return $prev;
}

=head2 search

Get a system by profile name 

=cut

sub search {
    my ( $class, @args ) = @_;
    my ( $rhnc, $name );

    if ( ref $class eq __PACKAGE__ && defined $class->{rhnc} ) {

        # OO context, eg $ch->list_systems
        $rhnc = $class->{rhnc};
    }
    elsif ( RHNC::Session::is_session($class) ) {

        # Called as RHNC::Channel::list_systems($rhnc)
        $rhnc = $class;
    }
    elsif ( !RHNC::Session::is_session( $rhnc = shift(@args) ) ) {
        croak "No RHNC client given";
    }

    $name = shift @args;

    my $res = $rhnc->call( 'system.searchByName', $name );

    foreach my $s (@$res) {
        if ( $s->{name} eq $name ) {
            my $self = RHNC::System->new( rhnc => $rhnc, %$s );
            return $self;
        }
    }
    return;
}

=head2 get

Get a system by profile id 

=cut

sub get {
    my ( $class, @args ) = @_;
    my ( $rhnc, $id_or_name );
    if ( ref $class eq __PACKAGE__ && defined $class->{rhnc} ) {

        # OO context, eg $sys->get
        $rhnc       = $class->{rhnc};
        $id_or_name = shift @args;
    }
    elsif ( RHNC::Session::is_session($class) ) {

        # Called as RHNC::System::get($rhnc)
        $rhnc = $class;
    }
    elsif ( __PACKAGE__ && !RHNC::Session::is_session( $rhnc = shift(@args) ) )
    {

        # RHNC::System->get( $rhnc )
        croak "No RHNC client given";
    }

    if ( !defined $id_or_name ) {
        $id_or_name = shift @args;
    }
    croak "No system id nor name given" if !defined $id_or_name;

    if ( !is_systemid($id_or_name) ) {
        my $res = RHNC::System->search( $rhnc, $id_or_name );
        $id_or_name = $res->{id};
    }

    my $res = $rhnc->call( 'system.getDetails', $id_or_name );
    croak "call failed" if !defined $res;

    # Normalize booleans
    $res->{lock_status} = $res->{lock_status}->value
      if ref $res->{lock_status} ne 'SCALAR';
    $res->{auto_update} = $res->{auto_update}->value
      if ref $res->{lock_status} ne 'SCALAR';

    my $self = RHNC::System->new(
        rhnc => $rhnc,
        (%$res)
    );

    return $self;
}

=head2 connection_path

Return the list of proxies that the given system connects through in
order to reach the server.

Returns array ref of hash :

  $aoh = $sys->connection_path();

  $aoh = [
      {
          position => 1,                 # first proxy from the system
          id       => $proxy_system_id,  # system id of the proxy
          hostname => 'proxy host name'  # proxy hostname, not profile name
      }
  ];

=cut

sub connection_path {
    my ($self) = @_;

    if ( !defined $self->{connection_path} ) {
        $self->{connection_path} =
          $self->{rhnc}->call( 'system.getConnectionPath', $self->{id} );

    }
    return $self->{connection_path};
}

=head2 cpu

Get CPU information as hash.

  $cpu = $sys->cpu;

  $cpu = {
      cache    => q( ),
      family   => q( ),
      mhz      => q( ),
      flags    => q( ),
      model    => q( ),
      vendor   => q( ),
      arch     => q( ),
      stepping => q( ),
      count    => q( ),
  };

=cut

sub cpu {
    my ($self) = @_;

    if ( !defined $self->{cpu} ) {
        $self->{cpu} = $self->{rhnc}->call( 'system.getCpu', $self->{id} );
    }
    return $self->{cpu};
}

=head2 custom_values

Return custom values set for the system.

  $cv = $sys->custom_values;
  $cv = {
      cv1    => q( ),
      cv2    => q( ),
  };

=cut

sub custom_values {
    my ($self) = @_;

    if ( !defined $self->{custom_values} ) {
        $self->{custom_values} =
          $self->{rhnc}->call( 'system.getCustomValues', $self->{id} );
    }
    return $self->{custom_values};
}

=head2 devices

Return devices of a system.

  $devices = $sys->devices;

  $devices = {
      device       => q( ),    # optional...
      device_class => q( ),    # CDROM, FIREWIRE, HD, USB, VIDEO, OTHER, etc.
      driver       => q( ),
      description  => q( ),
      bus          => q( ),
      pcitype      => q( ),
  };

=cut

sub devices {
    my ($self) = @_;

    if ( !defined $self->{devices} ) {
        $self->{devices} =
          $self->{rhnc}->call( 'system.getDevices', $self->{id} );
    }
    return $self->{devices};
}

=head2 dmi

Return DMI information of a system.

  $dmi = $sys->dmi;

  $dmi = {
      vendor        => q( ),
      system        => q( ),
      driver        => q( ),
      product       => q( ),
      asset         => q( ),
      board         => q( ),
      bios_release  => q( ),
      bios_vendor   => q( ),
      bios_version  => q( ),
  };


=cut

sub dmi {
    my ($self) = @_;

    if ( !defined $self->{dmi} ) {
        $self->{dmi} = $self->{rhnc}->call( 'system.getDmi', $self->{id} );
    }
    return $self->{dmi};

}

=head2 entitlements

=cut

sub entitlements {
    my ($self) = @_;

    if ( !defined $self->{entitlements} ) {
        $self->{entitlements} =
          $self->{rhnc}->call( 'system.getEntitlements', $self->{id} );
    }
    return $self->{entitlements};
}

=head2 event_history

=cut

sub event_history {

}

=head2 memory

=cut

sub memory {

}

=head2 network

=cut

sub network {

}

=head2 network_devices

=cut

sub network_devices {

}

=head2 registration_date

=cut

sub registration_date {

}

=head2 relevant_errata

All & by type

TODO : Should really be in RHNC::Errata...

=cut

my %errata_type = (
    RHSA => 'Security Advisory',
    RHBA => 'Bug Fix Advisory',
    RHEA => 'Product Enhancement Advisory',
    b    => 'Security Advisory',
    s    => 'Bug Fix Advisory',
    e    => 'Product Enhancement Advisory',
    bug  => 'Security Advisory',
    sec  => 'Bug Fix Advisory',
    enh  => 'Product Enhancement Advisory',
);

sub relevant_errata {
    my ( $self, $type ) = @_;
    my $res;

    if ( defined $type && defined $errata_type{$type} ) {
        $res = $self->{rhnc}->call( 'system.getRelevantErrataByType',
            $self->{id}, $errata_type{$type} );
    }
    else {
        my $res =
          $self->{rhnc}->call( 'system.getRelevantErrata', $self->{id} );
    }

    return $res;
}

=head2 base_channel

Get only.

=cut

sub base_channel {

}

=head2 running_kernel

=cut

sub running_kernel {

}

=head2 as_string

Return a printable string describing the system.

  print $sys->as_string;

=cut

sub as_string {
    my ($self) = @_;
    my $str;

    $str = $self->profile_name . ":\n";
    foreach my $k ( sort ( keys %{$self} ) ) {
        next if $k eq 'rhnc';
        if ( defined $self->{$k} ) {

            # SCALARs
            if ( !ref $self->{$k} && $self->{$k} ne q() ) {
                my $s = $self->{$k};
                $s =~ s/[\n\r]/,/g;
                $str .= "  $k: $s\n";
            }

            # structs & arrays specifics
            if ( $k eq 'connection_path' ) {
                $str .= "  $k:";
                $str .= join( q(,),
                    map { "$_->{position}:$_->{hostname}($_->{id})" }
                      @{ $self->{$k} } );
                $str .= "\n";
            }

            if ( $k eq 'devices' ) {
                foreach my $d ( @{ $self->{$k} } ) {
                    $str .= "  $k: ";
                    if ( defined $d->{device} && $d->{device} ne '' ) {
                        $str .= "$d->{device}:";
                    }
                    $str .=
"$d->{device_class},$d->{driver},$d->{description},$d->{bus},$d->{pcitype}\n";
                }
            }

            if ( $k eq 'cpu' || $k eq 'custom_values' || $k eq 'dmi' ) {
                $str .= "  $k:";
                my $c = $self->{$k};
                $str .= join( q(,), map { "$_=$c->{$_}" } keys %$c );
                $str .= "\n";
            }

        }
    }

    return $str;
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
