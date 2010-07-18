package RHNC::ActivationKey;

# $Id$

use warnings;
use strict;
use Params::Validate;
use Carp;

use base qw( RHNC );

use vars qw( %properties %valid_prefix );

=head1 NAME

RHNC::ActivationKey - Red Hat Network Client - Activation key handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Perhaps a little code snippet.

    use RHNC;

    my $foo = RHNC::ActivationKey->new( ... );
    my $foo = RHNC::ActivationKey->create( ... );
    ...

=head1 DESCRIPTION

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

#    * string key - Leave empty to have new key autogenerated.
#    * string description
#    * string baseChannelLabel - Leave empty to accept default.
#    * int usageLimit - If unlimited usage is desired, use the create API that does not include the parameter.
#    * array:
#          o
#          o string - Add-on entitlement label to associate with the key.
#                + monitoring_entitled
#                + provisioning_entitled
#                + virtualization_host
#                + virtualization_host_platform
#    * boolean universalDefault

#
# Accessors
#
my %entitlements = map { $_ => 1 } qw(
  monitoring_entitled
  provisioning_entitled
  virtualization_host
  virtualization_host_platform
);

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %properties = (
    rhnc => [ 0, undef, 0, undef ],
    key  => [
        0,
        sub {
            my @t = ( 0 .. 9, 'a' .. 'f' );
            my $l = scalar @t;
            return join( '', map { $t[ rand $l ] } 1 .. 32 );
        },
        0,
        undef
    ],
    description        => [ 1, undef, 0, undef ],
    base_channel_label => [ 0, q(),   0, undef ],
    usage_limit        => [ 0, 0,     0, undef ],
    entitlements       => [
        1,
        [],
        sub {
            foreach my $p (@_) {
                if ( !defined $entitlements{$p} ) { return 0; }
            }
            return 1;
        },
        undef
    ],
    universal_default => [ 1, $RHNC::_xmlfalse, 0, undef ],
    server_group_ids     => [ 0, [], 0, undef ],
    child_channel_labels => [ 0, [], 0, undef ],
    packages             => [ 0, [], 0, undef ],
    package_names        => [ 0, [], 0, undef ],
);

sub _setdefaults {
    my ( $self, @args ) = @_;

    foreach ( keys %properties ) {
        if ( ref $properties{$_}[DEFAULT] eq 'CODE' ) {
            $self->{$_} = $properties{$_}[DEFAULT]();
        }
        else {
            $self->{$_} = $properties{$_}[DEFAULT];
        }
    }
    return $self;
}

sub _validate_properties {
    my ( $self, @args ) = @_;

    foreach ( keys %properties ) {
        if ( $properties{$_}[MANDATORY] && !defined( $self->{$_} ) ) {
            croak "Mandatory parameter $_ not present in object " . $self->name;
        }

        if ( ref $properties{$_}[VALIDATE] eq 'CODE' ) {
            if ( $properties{$_}[VALIDATE]( $self->{$_} ) ) {
                croak "Property $_ does not pass validation for object"
                  . $self->name;
            }
        }
    }
    return $self;
}

=head2 new

Create and return a new activation key.
  
  $ak = RHNC::ActivationKey->new(
      rhnc => $rhnc,
      key  => $key,    # optional, if empty/undefined, a random key is set
      description       => $description,
      universal_default => $bool,          # true (!=0) or false (0)
  
      base_channel_label   => $base_channel_label,    # optional
      usage_limit          => $usage_limit,           # optional
      server_group_ids     => [ $id1, $id2, ],        # optional
      child_channel_labels => [ $chan1, $chan2, ],    # optional
      packages             => [ $pkg1, $pkg2, ],      # optional
      entitlements         => [
          qw( monitoring_entitled provisioning_entitled
              virtualization_host virtualization_host_platform )
      ],    # optional, zero or more values
  );
  
=cut

sub new {
    my ( $class, @args ) = @_;

    #$class = ref($class) || $class;
    $class = ref $class ? ref $class : $class;

    if ( $class ne __PACKAGE__ ) {
        unshift @args, $class;
    }

    my $self = {};
    bless $self, __PACKAGE__;

    # populate object from defaults
    $self->_setdefaults();

    my %v = map { $_ => 0 } ( keys %properties );

    # validate args given
    my %p = validate( @args, \%v );

    # populate object from @args
    for my $i ( keys %properties ) {
        if ( defined $p{$i} ) {
            $self->{$i} = $p{$i};
        }
    }

    if ( ref( $self->{universal_default} ) ne 'Frontier::RPC2::Boolean' ) {
        if ( $self->{universal_default} ) {
            $self->{universal_default} = $RHNC::_xmltrue;
        }
        else {
            $self->{universal_default} = $RHNC::_xmlfalse;
        }
    }

    # validate object content
    $self->_validate_properties;

    if ( defined $self->{rhnc} ) {
        $self->{rhnc}->manage($self);
    }

    return $self;
}

=head2 _uniqueid

Return activation key _uniqueid (key).

    $uuid = $ak->_uniqueid;

=cut

sub _uniqueid {
    my ( $self ) = @_;
    return $self->{key};
}

=head2 name

Return activation key name (key).

    $name = $ak->name;

=cut

sub name {
    my ( $self, @args ) = @_;
    my $prev = $self->{key};

    # TODO : haven't seen anything in the API to rename an activation key
    #    if (@args) {
    #        $self->{key} = shift @args;
    #    }
    return $prev;
}

=head2 description

Return or set activation key's description.

  $description = $ak->description;
  $description = $ak->description( $newdescription );

=cut

sub description {
    my ( $self, @args ) = @_;
    my $prev = $self->{description};
    if (@args) {
        $self->{description} = shift @args;
        $self->{rhnc}->call( 'activationkey.setDetails', $self->{key},
            { description => $self->{description}, } );
    }
    return $prev;
}

=head2 universal_default

Get or set universal_default property.
Return true if activation key is universal default, false otherwise.

  $is_default = $ak->universal_default;
  $is_default = $ak->universal_default( $bool );

=cut

sub universal_default {
    my ( $self, @args ) = @_;
    my $prev = q();

    $prev = $self->{universal_default}->value();
    if (@args) {
        $self->{universal_default} = shift @args;

        $self->{universal_default} = RHNC::_bool( $self->{universal_default} );

        $self->{rhnc}->call( 'activationkey.setDetails', $self->{key},
            { universal_default => $self->{universal_default}, } );

    }
    return $prev;
}

=head2 base_channel

Return or set activation key's base channel.

  $label = $ak->base_channel;
  $label = $ak->base_channel( $newbasechannel );

=cut

sub base_channel {
    my ( $self, @args ) = @_;
    my $prev = $self->{base_channel_label};
    if (@args) {
        $self->{base_channel_label} = shift @args;
        $self->{rhnc}->call( 'activationkey.setDetails', $self->{key},
            { base_channel_label => $self->{base_channel_label}, } );

    }
    return $prev;
}

=head2 entitlements

Return, set, add or remove array ref on entitlements for the
activation key.  As of API version 10.8 (Satellite 5.3), entitlements
can be any combination of: C<monitoring_entitled>,
C<provisioning_entitled>, C<virtualization_host>,
C<virtualization_host_platform>.

On modification, return the previous value via an array ref.

  $entitlements_ref = $ak->entitlements();
  $entitlements_ref = $ak->entitlements( [qw( )] );    # empty it
  $entitlements_ref =
    $ak->entitlements( [qw( provisioning_entitled )] );    # set
  $entitlements_ref =
    $ak->entitlements( set => [ qw( provisioning_entitled ) ] );    # set
  $entitlements_ref =
    $ak->entitlements( add => [ qw( provisioning_entitled ) ] );    # add
  $entitlements_ref =
    $ak->entitlements( remove => [ qw( provisioning_entitled ) ] ); # remove

=cut

sub entitlements {
    my ( $self, @args ) = @_;
    my $prev = \[];

    if ( defined $self->{entitlements} ) {
        $prev = $self->{entitlements};
    }

    if (@args) {
        my $c = shift @args;
        if ( $c eq 'add' ) {
            $self->{rhnc}->call( 'activationkey.addEntitlements', shift @args );
        }
        elsif ( $c eq 'remove' ) {
            $self->{rhnc}
              ->call( 'activationkey.removeEntitlements', shift @args );
        }
        elsif ( $c eq 'set' ) {
            $self->entitlements( 'remove' => $self->{entitlements} );
            $self->entitlements( 'add' => shift @args ) if @args;
        }
        elsif ( ref $c eq 'ARRAY' ) {

            # same as set
            $self->entitlements( 'remove' => $self->{entitlements} );
            $self->entitlements( 'add' => $c ) if @$c;
        }
    }
    return $prev;
}

=head2 server_group_ids

Return array ref on group ids for the activation key.

  $server_group_ids = $ak->server_group_ids;

=cut

sub server_group_ids {
    my ($self) = @_;

    if ( defined $self->{server_group_ids} ) {
        return $self->{server_group_ids};
    }
    return;
}

=head2 system_groups

Return, set, add or remove array ref on server groups for the activation key.
Return array ref on system groups for the activation key.

On modification, return the previous value via an array ref.

  $system_groups_ref = $ak->system_groups();              # get
  $system_groups_ref = $ak->system_groups( [qw( )] );     # empty it
  $system_groups_ref =
    $ak->system_groups( [qw( RHEL5 i386 )] );             # set
  $system_groups_ref =
    $ak->system_groups( set => [ qw( RHEL5 i386 ) ] );    # set
  $system_groups_ref =
    $ak->system_groups( add => [ qw( RHEL5 i386 ) ] );    # add
  $system_groups_ref =
    $ak->system_groups( remove => [ qw( RHEL5 i386 ) ] ); # remove

System groups may be specified either by name, or by id.

=cut

sub system_groups {
    my ( $self, @args ) = @_;
    my $prev = [];

    my $aksg = $self->{server_group_ids};
    if ( defined $aksg ) {
        my $groups = [];

        foreach my $sgid (@$aksg) {
            my $sg = RHNC::SystemGroup->get( $self->{rhnc}, $sgid );
            push @$groups, $sg->name();
        }
        $prev = $groups;
    }

    if (@args) {
        my $c      = shift @args;
        my $sg_ref = shift @args;

        if ( $c eq 'add' && ref $sg_ref eq 'ARRAY' ) {
            my $sgids = [];
            foreach my $sg (@$sg_ref) {
                if ( RHNC::SystemGroup::is_system_group_id($sg) ) {
                    push @$sgids, $sg;
                }
                else {
                    my $sgo = RHNC::SystemGroup->get( $self->{rhnc}, $sg );
                    push @$sgids, $sgo->id if defined $sgo;
                }
            }
            $self->{rhnc}
              ->call( 'activationkey.addServerGroups', $self->{key}, $sgids );
            $self->{server_group_ids} = $sgids;
        }
        elsif ( $c eq 'remove' && ref $sg_ref eq 'ARRAY' ) {
            my $sgids = [];
            foreach my $sg (@$sg_ref) {
                if ( RHNC::SystemGroup::is_system_group_id($sg) ) {
                    push @$sgids, $sg;
                }
                else {
                    my $sgo = RHNC::SystemGroup->get( $self->{rhnc}, $sg );
                    push @$sgids, $sgo->id if defined $sgo;
                }
            }

            $self->{rhnc}
              ->call( 'activationkey.removeServerGroups', $self->{key},
                $sgids );
            $self->{server_group_ids} = $sgids;
        }
        elsif ( $c eq 'set' && ref $sg_ref eq 'ARRAY' ) {
            $self->system_groups( 'remove' => $self->{server_group_ids} );
            $self->system_groups( 'add'    => $sg_ref );
        }
        elsif ( ref $c eq 'ARRAY' ) {
            $self->system_groups( 'remove' => $self->{server_group_ids} );
            $self->system_groups( 'add' => $c ) if @$c;
        }
    }

    return $prev;
}

=head2 child_channels

Return, set, add or remove  array ref on group ids for the activation
key.

On modification, return the previous value via an array ref.

  $child_channels = $ak->child_channel();

  $child_channels = $ak->child_channels( add => [qw( label1 label2 )] );
  $child_channels = $ak->child_channels( remove => [qw( label1 label2 )] );
  $child_channels = $ak->child_channels( set => [qw( label1 label2 )] ); 
  $child_channels = $ak->child_channels( [qw( label1 label2)] ); # same as set

=cut

sub child_channels {
    my ( $self, @args ) = @_;
    my $prev = \[];
    my $chan_ref;

    if ( defined $self->{child_channel_labels} ) {
        $prev = $self->{child_channel_labels};
    }
    if (@args) {
        my $c = shift @args;
        $chan_ref = shift @args;

        if ( $c eq 'add' && ref $chan_ref eq 'ARRAY' ) {
            $self->{rhnc}->call( 'activationkey.addChildChannels',
                $self->{key}, $chan_ref );
        }
        elsif ( $c eq 'remove' && ref $chan_ref eq 'ARRAY' ) {
            $self->{rhnc}->call( 'activationkey.removeChildChannels',
                $self->{key}, $chan_ref );
        }
        elsif ( $c eq 'set' && ref $chan_ref eq 'ARRAY' ) {
            $self->child_channels( 'remove' => $self->{child_channel_labels} );
            $self->child_channels( 'add'    => $chan_ref );
        }
        elsif ( ref $c eq 'ARRAY' ) {
            $self->child_channels( 'remove' => $self->{child_channel_labels} );
            $self->child_channels( 'add' => $c ) if @$c;
        }
    }
    return $prev;
}

=head2 usage_limit

Get or set usage_limit property of an activation key.

On modification, return the previous value.

  $usage_limit = $ak->usage_limit;

=cut

sub usage_limit {
    my ( $self, @args ) = @_;
    my $prev = 0;

    if ( defined $self->{usage_limit} ) {
        $prev = $self->{usage_limit};
    }
    if (@args) {
        $self->{usage_limit} = shift @args;
        $self->{rhnc}->call( 'activationkey.setDetails', $self->{key},
            { usage_limit => $self->{usage_limit}, } );

    }
    return $prev;
}

=head2 packages


Return, set, add or remove array ref on packages for the
activation key.

On modification, return the previous value.

Return or set packages.

  $pkg_array_ref = $ak->packages;

=cut

sub packages {
    my ( $self, @args ) = @_;
    my $prev = \[];

    if ( defined $self->{package_names} ) {
        $prev = $self->{package_names};
    }
    if (@args) {
        my $c           = shift @args;
        my $pkglist_ref = shift @args;

        my @pkglist;
        foreach my $p (@$pkglist_ref) {

            my ( $n, $v, $r, $a ) = RHNC::Package::split_package_name($p);
            push @pkglist,
              {
                name => RHNC::Package::join_package_name(
                    { name => $n, version => $v, release => $r }
                ),
                ( defined $a ? ( arch => $a ) : () )
              };
        }

        if ( $c eq 'add' && ref $pkglist_ref eq 'ARRAY' ) {
            $self->{rhnc}
              ->call( 'activationkey.addPackages', $self->{key}, \@pkglist );
        }
        elsif ( $c eq 'remove' && ref $pkglist_ref eq 'ARRAY' ) {
            $self->{rhnc}
              ->call( 'activationkey.removePackages', $self->{key}, \@pkglist );
        }
        elsif ( $c eq 'set' && ref $pkglist_ref eq 'ARRAY' ) {
            $self->packages( 'remove' => $self->{package_names} );
            $self->packages( 'add'    => $pkglist_ref );
        }
        elsif ( ref $c eq 'ARRAY' ) {
            $self->packages( 'remove' => $self->{package_names} );
            $self->packages( 'add' => $c ) if @$c;
        }
    }
    return $prev;
}

=head2 create

Create a new activation key.

    $ak->create();
    $ak = RHNC::ActivationKey->create(
        rhnc               => $rhnc,
        key                => $keyname,       # optional or can be empty
        description        => $description,
        base_channel_label => $channel,       # optional or can be empty
        universal_default  => $bool,
        entitlements       => [
            qw( monitoring_entitled provisioning_entitled
              virtualization_host virtualization_host_platform )
        ],
        usage_limit => $bool,
    );

=cut

sub create {
    my ( $class, @args ) = @_;

    $class = ref($class) || $class;
    if ( $class ne __PACKAGE__ ) {
        unshift @args, $class;
        $class = __PACKAGE__;
    }

    my $self = RHNC::ActivationKey->new(@args);

    croak 'No RHNC client to persist to, exiting'
      if !defined $self->{rhnc};

    $self->{rhnc}->manage($self);

    my $res = $self->{rhnc}->call(
        'activationkey.create', $self->{key},
        $self->{description},   $self->{base_channel_label},
        $self->{entitlements},  $self->{universal_default},
    );
    croak 'Create did not work' if !defined $res;
    $self->{key} = $res;

    return $self;
}

=head2 destroy 

Destry (delete) an activation key from Satellite.

    $ak->destroy();

=cut

sub destroy {
    my ( $self, @args ) = @_;

    my $res = $self->{rhnc}->call( 'activationkey.delete', $self->{key} );

    undef $self;

    return $res;
}

=head2 list

Return a list of activation keys in the Satellite.

  

=cut

sub list {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::ActivationKey' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::ActivationKey::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::ActivationKey->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }

    my $res = $rhnc->call('activationkey.listActivationKeys');

    my $l = [];
    foreach my $o (@$res) {
        push @$l, RHNC::ActivationKey->new($o);
    }

    return $l;
}

=head2 get

Get from Satellite a specific activation key. Returns a
C<RHNC::ActivationKey> object.

  $ak = RHNC::SystemGroup::get( $RHNC, $name );
  $ak = RHNC::SystemGroup->get( $RHNC, $name );
  $ak = $key->get( $name );

=cut

sub get {
    my ( $class, @args ) = @_;
    my $rhnc;

    if ( ref $class eq __PACKAGE__ && defined $class->{rhnc} ) {

        # OO context, eg $ak->get
        $rhnc = $class->{rhnc};
    }
    elsif ( RHNC::Session::is_session($class) ) {
        $rhnc = $class;
    }
    elsif ( !RHNC::Session::is_session( $rhnc = shift(@args) ) ) {
        croak "No RHNC client given";
    }

    my $k = shift @args
      or croak "No activation key specified in get";

    my $res = $rhnc->call( 'activationkey.getDetails', $k );

    if ( defined $res ) {
        my $ak = __PACKAGE__->new( %{$res} );
        $rhnc->manage($ak);
        return $ak;
    }
    return;
}

=head2 as_string

Returns a printable string to describe activation key.

    print $ak->as_string;

=cut

sub as_string {
    my ($self) = @_;

    my $output;

    $output = "key: " . $self->name();
    $output .= "\n  description: " . $self->description();
    $output .= "\n  base_channel: " . $self->base_channel();
    $output .= "\n  entitlements: " . join( ',', @{ $self->entitlements() } );
    $output .= "\n  universal_default: " . $self->universal_default();
    $output .= "\n  package_names: " . join( ',', @{ $self->packages() } );
    $output .= "\n  usage_limit: " . $self->usage_limit();
    $output .=
      "\n  server_group_ids: " . join( ',', @{ $self->server_group_ids() } );
    $output .= "\n  system_groups: " . join( ',', @{ $self->system_groups() } );
    $output .=
      "\n  child_channels: " . join( ',', @{ $self->child_channels() } );
    $output .= "\n";

    return $output;
}

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

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

    perldoc RHNC::ActivationKey


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

1;    # End of RHNC::ActivationKey
