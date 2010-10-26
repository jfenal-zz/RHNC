package RHNC::Channel;

# $Id$

use strict;
use warnings;
use Params::Validate;
use Carp;
use Data::Dumper;
use base qw(RHNC);

use vars qw( %properties %valid_prefix );
use Exporter;
our @EXPORT_OK = qw( $VERSION %properties $arch_ref );

=head1 NAME

RHNC::Channel - Red Hat Network Client - Software Channel handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::Channel;

    my $foo = RHNC::Channel->new( ... );
    my $foo = RHNC::Channel->create( ... );
    ...

See methods details below.

=head1 DESCRIPTION

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

my %entitlements = map { $_ => 1 } values %RHNC::entitlement;

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

our $arch_ref;

# channel-ia32    channel-ia64    channel-sparc   channel-alpha
# channel-s390    channel-s390x   channel-iSeries channel-pSeries
# channel-x86_64  channel-ppc     channel-sparc-sun-solaris
# channel-i386-sun-solaris

my %properties = (
    rhnc                 => [ 0, undef, undef, undef ],
    name                 => [ 1, undef, undef, undef ],
    label                => [ 1, undef, undef, undef ],
    summary              => [ 1, undef, undef, undef ],
    description          => [ 1, undef, undef, undef ],
    parent_label         => [ 0, q(),   undef, undef ],
    parent_channel_label => [ 0, q(),   undef, undef ],
    id                   => [ 0, undef, undef, undef ],
    provider_name        => [ 0, undef, undef, undef ],
    packages             => [ 0, undef, undef, undef ],
    systems              => [ 0, undef, undef, undef ],
    arch_name            => [ 1, undef, undef, undef ],
    arch                 => [ 1, undef, undef, undef ],
    maintainer_name      => [ 0, undef, undef, undef ],
    maintainer_email     => [ 0, undef, undef, undef ],
    maintainer_phone     => [ 0, undef, undef, undef ],
    support_policy       => [ 0, undef, undef, undef ],
    gpg_key_url          => [ 0, undef, undef, undef ],
    gpg_key_id           => [ 0, undef, undef, undef ],
    gpg_key_fp           => [ 0, undef, undef, undef ],
    end_of_life          => [ 0, undef, undef, undef ],
    checksum_label       => [ 0, undef, undef, undef ],
    yumrepo_label        => [ 0, undef, undef, undef ],
    yumrepo_last_sync    => [ 0, undef, undef, undef ],
    yumrepo_source_url   => [ 0, undef, undef, undef ],
);

sub _setdefaults {
    my ( $self, @args ) = @_;

    foreach ( keys %properties ) {
        $self->{$_} = $properties{$_}[DEFAULT];
    }
    return $self;
}

sub _missing_parameter {
    my ($parm) = @_;

    confess "Missing parameter $parm";
}

=head2 _uniqueid

Returns a C<RHNC::Channel> unique id (label).

  $id = $chan->_uniqueid;

=cut

sub _uniqueid {
    my ($self) = @_;
    return $self->{label};
}

=head2 is_channel_id

Returns true if channel id B<looks> valid, false otherwise.

  $chan->is_channel_id;

=cut

sub is_channel_id {
    my ($s) = shift;
    return 1 if $s =~ m{ \A \d+ \z }imxs;
    return 0;
}

=head2 new

Create a new RHNC::Channel object from its description.
    
    $c = RHNC::Channel->new(
        label => "label",
        name => "name",
        summary => "summary",
        archLabel => "summary", # arch_name in structure from getDetails
        parentLabel => "parent-label",
        );

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    bless $self, $class;

    my %v = map { $_ => 0 } keys %properties;

    $self->_setdefaults();
    my %p = validate( @args, \%v );

    # populate object from either @args or default
    for my $i ( keys %properties ) {
        if ( defined $p{$i} ) {
            $self->{$i} = $p{$i};
        }
    }
    return $self;
}

=head2 list_arches

Returns the list of _all_ available arches, as a HASH ref ( C<label => name> ).

  my $arches_list = RHNC::Channel::list_arches($rhnc);
  my $arches_list = RHNC::Channel->list_arches($rhnc);
  my $arches_list = $channel->list_arches();

=cut

sub list_arches {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );

    my $res = $rhnc->call("channel.software.listArches");

    my $arch_ref = {};
    %$arch_ref = map { $_->{label} => $_->{name} } @{$res};
    return $arch_ref;
}

=head2 list_errata

Returns the list of errata for the channels specified.

  my @errata_list = RHNC::Channel::list_errata($rhnc, $channel);
  my @errata_list = RHNC::Channel->list_errata($rhnc, $channel);
  my @errata_list = $channel->list_errata();

=cut

sub list_errata {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );

    my $id_or_name;

    if ( ref $self eq __PACKAGE__ ) {
        $id_or_name = $self->label();
    }
    else {
        $id_or_name = shift @args;
    }
    croak "No channel to give errata for" if !defined $id_or_name;

    if ( is_channel_id($id_or_name) ) {
        $id_or_name = __PACKAGE__->get( $rhnc, $id_or_name )->label;
    }

    my $res = $rhnc->call( 'channel.software.listErrata', $id_or_name );

    my $errata = {};
    %$errata = map { $_->{advisory} => $_ } @{$res};
    return $errata;
}

=head2 list_packages

Return the list of packages in the channel.

  $packages = $ch->list_packages();

=cut

sub list_packages {
    my ( $self, $update ) = @_;
    my $rhnc;
    my $id_or_name;
    my $plist = [];

    my $list;
    if ( ( defined $update || !defined $self->{list_packages} )
        && defined $self->{rhnc} )
    {
        $rhnc = $self->{rhnc};
        $list =
          $self->{rhnc}
          ->call( 'channel.software.listAllPackages', $self->label() );

        foreach my $p (@$list) {
            my $p =
              RHNC::Package->new( ( defined $rhnc ? ( rhnc => $rhnc ) : () ),
                (%$p) );
            push @$plist, $p;
        }

        $self->{list_packages} = $plist;
    }
    return $self->{list_packages};
}

=head2 latest_packages

Returns the list of latest_packages for the channels specified.

  my $latest_packages = $channel->latest_packages();

=cut

sub latest_packages {
    my ( $self, $update ) = @_;
    my $rhnc;
    my $id_or_name;
    my $plist = [];

    my $list;
    if ( ( defined $update || !defined $self->{latest_packages} )
        && defined $self->{rhnc} )
    {
        $rhnc = $self->{rhnc};
        $list =
          $self->{rhnc}
          ->call( 'channel.software.listLatestPackages', $self->label() );

        foreach my $p (@$list) {
            my $p =
              RHNC::Package->new( ( defined $rhnc ? ( rhnc => $rhnc ) : () ),
                (%$p) );
            push @$plist, $p;
        }

        $self->{latest_packages} = $plist;
    }
    return $self->{latest_packages};
}

=head2 list_systems

Returns the list of systems for the channels specified.

  my @systems_list = RHNC::Channel::list_systems($rhnc, $channel);
  my @systems_list = RHNC::Channel->list_systems($rhnc, $channel);
  my @systems_list = $channel->list_systems();

=cut

sub list_systems {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );
    my $id_or_name;

    if ( ref $self eq __PACKAGE__ ) {
        $id_or_name = $self->label();
    }
    else {
        $id_or_name = shift @args;
    }

    if ( is_channel_id($id_or_name) ) {
        $id_or_name = __PACKAGE__->get( $rhnc, $id_or_name )->label;
    }

    my $res =
      $rhnc->call( 'channel.software.listSubscribedSystems', $id_or_name );

    my $systems = {};
    %$systems = map { $_->{id} => $_->{name} } @{$res};
    return $systems;
}

=head2 id

Return channel id

  $id = $ch->id;

=cut

sub id {
    my ( $self, @p ) = @_;

    if ( !defined $self->{id} ) {
        confess 'id not defined';
    }

    return $self->{id};
}

=head2 name

Return channel name (label).

  $name = $ch->name;

=cut

sub name {
    my ( $self, @p ) = @_;

    if ( !defined $self->{name} ) {
        confess 'name not defined';
    }

    return $self->{name};
}

=head2 label

  $label = $ch->label;

=cut

sub label {
    my ( $self, @p ) = @_;

    if ( !defined $self->{label} ) {
        confess 'label not defined';
    }

    return $self->{label};
}

=head2 parent_label

Return parent label.

  $label = $ch->parent_label;

=cut

sub parent_label {
    my ( $self, @p ) = @_;

    if ( !defined $self->{parent_label} ) {
        if ( defined $self->{parent_channel_label} ) {
            $self->{parent_label} = $self->{parent_channel_label};
        }
        else {
            $self->{parent_label} = q();
        }
    }

    return $self->{parent_label};
}

=head2 arch

Return channel architecture.

  $arch = $ch->arch;

=cut

sub arch {
    my ( $self, @p ) = @_;

    if ( !defined $self->{arch} ) {
        if ( defined $self->{arch_name} ) {
            $self->{arch} = $self->{arch_name};
        }
        else {
            confess "Arch not defined for this channel $self->{label}";
        }
    }

    return $self->{arch};
}

=head2 provider_name

Return channel provider channel if set, empty string otherwise.

  $provider_name = $ch->provider_name;

=cut

sub provider_name {
    my ( $self, @p ) = @_;

    if ( defined $self->{provider_name} ) {
        return $self->{provider_name};
    }

    return q();
}

=head2 packages

Return number of packages in the channel.

  $nbpackages = $ch->packages();

=cut

sub packages {
    my ( $self, @p ) = @_;

    if ( !defined $self->{packages} ) {
        $self->list_packages();
    }

    return $self->{packages};
}

=head2 systems

  $systems = $ch->systems;

=cut

sub systems {
    my ( $self, @p ) = @_;

    if ( defined $self->{systems} ) {
        return $self->{systems};
    }

    return 0;
}

=head2 create

Create a new channel

  $c = RHNC::Channel->create(
      rhnc                 => $rhnc,
      label                => $label,
      name                 => $name,
      summary              => $summary,
      arch_name            => $arch,
      parent_channel_label => $parent,
  );

=cut

sub create {
    my ( $self, @args ) = @_;

    if ( !ref $self ) {
        $self = __PACKAGE__->new(@args);
    }

    foreach my $p (
        qw( label name summary arch_name
        parent_channel_label  )
      )
    {
        if ( !defined $self->{$p} ) {
            _missing_parameter($p);
        }
    }

    confess 'No RHNC client to persist to, exiting'
      if !defined $self->{rhnc};

    my $res;
    $res =
      $self->{rhnc}
      ->call( 'channel.software.create', $self->{label}, $self->{name},
        $self->{summary}, $self->{arch_name}, $self->{parent_channel_label},
      );
    if ( defined $res ) {
        $self->{rhnc}->manage($self);
        return $self;
    }
    return;
}

=head2 destroy 

=cut

sub destroy {
    my ( $self, @args ) = @_;

    my $res = $self->{rhnc}->call( 'channel.software.delete', $self->label() );

    return $res;
}

=head2 list

List channels. Returns array ref of objects of type C<RHNC::Channel>.

  my $channel_list = RHNC::Channel::list($rhnc);
  my $channel_list = RHNC::Channel->list($rhnc);
  my $channel_list = $channel->list();

=cut

sub list {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );

    # 1st, query all channels
    my $res1 = $rhnc->call('channel.listAllChannels');
    my %hres1 = map { $_->{label} => $_ } @$res1;

    # 2nd, query software channels, to get more information
    my $res2 = $rhnc->call('channel.listSoftwareChannels');
    my %hres2 = map { $_->{label} => $_ } @$res2;

    # put information in %hres2 in %hres1
    foreach my $softchan ( keys %hres2 ) {
        foreach my $j ( keys %{ $hres2{$softchan} } ) {
            $hres1{$softchan}{$j} = $hres2{$softchan}{$j};
        }
    }

    my $l = [];
    foreach my $output ( keys %hres1 ) {
        my $c = __PACKAGE__->new( $hres1{$output} );
        $rhnc->manage($c);
        push @$l, $c;
    }

    return $l;
}

=head2 get

Return detailled information about channel.

  my $chan  = RHNC::Channel::get( $rhnc, $label );  # $label or $id
  my $chan2 = RHNC::Channel->get( $rhnc, $label );  # $label or $id
  my $chan3 = $chan->get( $label );                 # $label or $id
  my $chan4 = $chan->get();                         # $label or $id

=cut

sub get {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );

    my $id_or_name = shift @args;
    if ( ref $self eq __PACKAGE__ && !defined $id_or_name ) {
        $id_or_name = $self->label();
    }

    if ( !defined $id_or_name ) {
        croak "No channel id or name specified in get";
    }

    my $res = $rhnc->call( 'channel.software.getDetails', $id_or_name );

    if ( defined $res ) {
        my $channel = __PACKAGE__->new( %{$res} );
        $channel->packages();

        $rhnc->manage($channel);
        return $channel;
    }
    return;
}

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

See L<RHNC>.

=head1 DEPENDENCIES

=over 4

=item 1 L<Frontier::Client>

=item 1 L<Params::Validate>

=back

=head1 INCOMPATIBILITIES

Requires Red Hat Network Satellite 5.3 minimum.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Jerome Fenal, C<< <jfenal at free.fr> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Channel


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

1;    # End of RHNC::Channel
