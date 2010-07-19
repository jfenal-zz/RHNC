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
    my $system;

    if ( ref $self eq __PACKAGE__ ) {
        return $self->{id};
    }

    if ( $self eq __PACKAGE__ ) {
        $rhnc = shift @args;
    }
    elsif ( ref $self eq 'RHNC::Session' ) {
        $rhnc   = $self;
    }
    else {
        return;
    }

    $system = shift @args;
    print STDERR "system = $system\n";
    my $res = $rhnc->call('system.getId', $system );
    if ( @$res eq 1 ) {
        return $res->[0]->{id};
    }
    return;
}

=head2 _uniqueid

Return system's _uniqueid (id)

  $uuid = $sys->_uniqueid;

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
    if ( !defined $self->{auto_update} ) { $self->get_details; }
    my $prev = $self->{auto_update};

    if (@args) {
        $self->{auto_update} = shift @args;

        $self->{rhnc}->call( 'system.setDetails', $self->{id},
            { auto_errata_update => RHNC::_bool( $self->{auto_update} ) } );
    }

    return $prev;
}

=head2 release           

Get system's release.

  $release = $sys->release;

=cut

sub release {
    my ($self) = @_;
    if ( !defined $self->{release} ) { $self->get_details; }
    return $self->{release};
}

=head2 address1          

Get or set address1 attribute of a system.

  $a1 = $sys->address1;
  $sys->address1( 'new address' );

=cut

sub address1 {
    my ( $self, @args ) = @_;
    if ( !defined $self->{address1} ) { $self->get_details; }
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
    if ( !defined $self->{address2} ) { $self->get_details; }
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
    if ( !defined $self->{city} ) { $self->get_details; }
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
    if ( !defined $self->{state} ) { $self->get_details; }
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
    if ( !defined $self->{country} ) { $self->get_details; }
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
    if ( !defined $self->{building} ) { $self->get_details; }
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
    if ( !defined $self->{room} ) { $self->get_details; }

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
    if ( !defined $self->{rack} ) { $self->get_details; }
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
    if ( !defined $self->{description} ) { $self->get_details; }
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
    if ( !defined $self->{hostname} ) { $self->get_details; }
    return $self->{hostname};
}

=head2 osa_status        

Return system's OSA status.

  $hostname = $sys->osa_status;

Returns one in C<qw( unknown offline online )>.

=cut

sub osa_status {
    my ($self) = @_;
    if ( !defined $self->{osa_status} ) { $self->get_details; }

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
    if ( !defined $self->{lock_status} ) { $self->get_details; }

    my $prev = $self->{lock_status};

    if (@args) {
        $self->{lock_status} = shift @args;
        my $v = RHNC::_bool( $self->{lock_status} );

        $self->{rhnc}->call( 'system.setLockStatus', $self->{id},
            RHNC::_bool( $self->{lock_status} ) );
    }

    return $prev;
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
    elsif ( __PACKAGE__ && RHNC::Session::is_session( $args[0] ) )
    {
        # RHNC::System->get( $rhnc )
        $rhnc = shift @args;
    }
    else {
        croak "No RHNC client given";
    }
    if ( !defined $id_or_name ) {
        $id_or_name = shift @args;
    }
    croak "No system id nor name given" if !defined $id_or_name;

    if ( !is_systemid($id_or_name) ) {
        my $res = RHNC::System->id( $rhnc, $id_or_name );
        if (defined $res) {
            $id_or_name = $res;
        }
        else {
            croak "No such system profile name: $id_or_name";
        }
    }

    my $res = $rhnc->call( 'system.getDetails', $id_or_name );
    croak "call failed" if !defined $res;

    # Normalize booleans
    $res->{lock_status} = $res->{lock_status}->value
      if ref $res->{lock_status} ne 'SCALAR';
    $res->{auto_update} = $res->{auto_update}->value
      if ref $res->{lock_status} ne 'SCALAR';

    my $self = __PACKAGE__->new(
        rhnc => $rhnc,
        (%$res)
    );
    $self->{rhnc}->manage($self);

    return $self;
}

=head2 get_details

Get more details about current object, and populate results.

=cut 

sub get_details {
    my ($self) = @_;

    my $res = $self->{rhnc}->call( 'system.getDetails', $self->{id} );

    foreach my $k ( keys %$res ) {
        $self->{$k} = $res->{$k};
    }

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

Returns array ref to list of all entitlements.

  $e = $sys->entitlements;

=cut

sub entitlements {
    my ($self) = @_;
    my $prev = $self->{entitlements};

    if ( !defined $self->{entitlements} ) {
        $self->{entitlements} =
          $self->{rhnc}->call( 'system.getEntitlements', $self->{id} );
    }
    return $self->{entitlements};
}

=head2 event_history

=cut

#sub event_history {

#}

=head2 memory

Return memory information about a system.

  $memory = $sys->memory;

  $memory = {
      ram  => q( ),
      swap => q( ),
  };


=cut

sub memory {
    my ($self) = @_;

    if ( !defined $self->{memory} ) {
        $self->{memory} = $self->{rhnc}->call( 'system.getMemory', $self->{id} );
    }
    return $self->{memory};
}

=head2 network

Get the IP address and hostname for a given server. 

  $network = $sys->network;

  $network = {
      ip       => q( ),
      hostname => q( ),
  };


=cut

sub network {
    my ($self) = @_;

    if ( !defined $self->{network} ) {
        $self->{network} = $self->{rhnc}->call( 'system.getNetwork', $self->{id} );
    }
    return $self->{network};

}

=head2 network_devices

Returns the network devices for the given server, as an ARRAY of HASH. 

  $ndev = $sys->network_devices;

  $ndev = [
    ip               => q( ),
    interface        => q( ),
    netmask          => q( ),
    hardware_address => q( ),
    module           => q( ),
    broadcast        => q( ),
  ];

=cut

sub network_devices {
    my ($self) = @_;

    if ( !defined $self->{network_devices} ) {
        $self->{network_devices} = $self->{rhnc}->call( 'system.getNetworkDevices', $self->{id} );
    }
    return $self->{network_devices};


}

=head2 registration_date

Returns the date the system was registered (dateTime.iso8601).

  $regdate = $sys->registration_date;

=cut

sub registration_date {
    my ($self) = @_;

    if ( !defined $self->{registration_date} ) {
        $self->{registration_date} = $self->{rhnc}->call( 'system.getRegistrationDate', $self->{id} );
    }
    return $self->{registration_date};
}

=head2 relevant_errata

Retrieve relevant errata applicable to a particular system.
Get either all, or by type.

  $e = $sys->relevant_errata;
  $e = $sys->relevant_errata( 'RHBA' );
                                # or RHSA, or RHEA, see
                                #  L<RHNC::Errata> for more shortcuts.

=cut

sub relevant_errata {
    my ( $self, $type ) = @_;
    my $res;

    if ( defined $type && defined $RHNC::Errata::errata_type{$type} ) {
        $res = $self->{rhnc}->call( 'system.getRelevantErrataByType',
            $self->{id}, $RHNC::Errata::errata_type{$type} );
    }
    else {
        $res =
          $self->{rhnc}->call( 'system.getRelevantErrata', $self->{id} );
    }

    return $res;
}

=head2 available_base_channels

Return an array ref to the list of available base channels one can
subscribe a system to.
The first element in the array if the current base channel;

  my $ac = $sys->available_base_channel;

=cut

sub available_base_channels {
    my ( $self, @args ) = @_;

    my $res = $self->{rhnc}
          ->call( 'system.listSubscribableBaseChannels', $self->{id});
    my $ac = [];
    my @bc;
    my $current;
    foreach my $c ( @$res ) {
        if ($c->{current_base} ) {
            $current = $c->{label};
        }
        else {
            push @bc, $c->{label};
        }
    }
    @$ac = ( $current, @bc );
    return $ac;
}

=head2 base_channel

Return or set base_channel for the system.

  my $channel_label = $sys->base_channel;
  my $old_channel_label = $sys->base_channel($new_channel_label);

=cut

sub base_channel {
    my ( $self, @args ) = @_;
    if (! defined $self->{base_channel} ) {
        my $res=  $self->{rhnc}
          ->call( 'system.getSubscribedBaseChannel', $self->{id} );

        $self->{base_channel} = $res->{label};
    }
    my $prev = $self->{base_channel};

    if (@args) {
        $self->{base_channel} = shift @args;
        $self->{rhnc}
          ->call( 'system.setBaseChannel', $self->{id}, $self->{base_channel} );
    }
    return $prev;
}


=head2 available_child_channels

Return an array ref to the list of available child channels one can
subscribe a system to.

  my $ac = $sys->available_base_channel;
  my $ac = $sys->available_base_channel(1)
    ;    # get really all child channels, including currently subcribed ones.

=cut

sub available_child_channels {
    my ( $self, @args ) = @_;
    my $all = shift @args;

    my $res = $self->{rhnc}
          ->call( 'system.listSubscribableChildChannels', $self->{id});
    my $ac = [];

    if ($all) {
        push @$ac, @{ $self->child_channels() };
    }

    my @cc = map { $_->{label } } @$res;

    push @$ac, @cc;
    return $ac;
}

=head2 child_channels

Return or set child channels for the system.

  my @channel_labels = @{ $sys->child_channels };
  my $old_channel_labels_ref = $sys->child_channels($new_child_channel);
  my $ocl = $sys->child_channels( add => [ @list ] );
  my $ocl = $sys->child_channels( remove => [ @list ] );
  my $ocl = $sys->child_channels( set => [ @list ] );

=cut

sub child_channels {
    my ( $self, @args ) = @_;
    if ( !defined $self->{child_channels} ) {
        my $res =
          $self->{rhnc}
          ->call( 'system.listSubscribedChildChannels', $self->{id} );

        $self->{child_channels} = [];
        push @{ $self->{child_channels} }, map { $_->{label} } @$res;
    }
    my $prev = $self->{child_channels};

    if (@args) {
        my $c        = shift @args;
        my $chan_ref = shift @args;
        my @chans;

        if ( $c eq 'add' && ref $chan_ref eq 'ARRAY' ) {
            @chans = @$prev;
            push @chans, @$chan_ref;
        }
        elsif ( $c eq 'remove' && ref $chan_ref eq 'ARRAY' ) {
            my %chanh = map { $_ => 1 } @$prev;
            foreach my $i (@$chan_ref) {
                delete $chanh{$i};
            }
            @chans = keys %chanh;
        }
        elsif ( $c eq 'set' && ref $chan_ref eq 'ARRAY' ) {
            @chans = @$chan_ref;
        }
        elsif ( ref $c eq 'ARRAY' ) {
            @chans = @$c;
        }

        # set in Satellite if list not empty
        my $res;
        if (@chans) {
            $res =
              $self->{rhnc}
              ->call( 'system.setChildChannels', $self->{id}, \@chans );
        }
    }
    return $prev;
}

=head2 running_kernel

Get current running kernel information.

  $k = $sys->running_kernel;

=cut

sub running_kernel {
    my ($self) = @_;

    if ( !defined $self->{running_kernel} ) {
        $self->{running_kernel} =
          $self->{rhnc}->call( 'system.getRunningKernel', $self->{id} );
    }
    return $self->{running_kernel};
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
            if ( !ref $self->{$k} ) { #&& $self->{$k} ne q() ) {
                my $s = $self->{$k};
                $s =~ s/[\n\r]/,/g;
                $str .= "  $k: $s\n";
            }

            # HASHes
            if ( ref $self->{$k} eq 'HASH' ) {
                $str .= "  $k:";
                my $c = $self->{$k};
                $str .= join( q(,), map { "$_=$c->{$_}" } keys %$c );
                $str .= "\n";
            }

            if ( $k eq 'entitlements' ) {
                $str .= "  $k: ";
                $str .= join( q(,), @{ $self->{$k} } );
                $str .= "\n";
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
        }
    }

    return $str;
}

=head1 AUTHOR

Jerome Fenal, C<< <jfenal at free.fr> >>

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

Copyright 2009 Jerome Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::System
