package RHNC::Channel;

# $Id$

use strict;
use warnings;
use Params::Validate;
use Carp;
use Data::Dumper;

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

Quick summary of what the module does.

Perhaps a little code snippet.

    use RHNC::Channel;

    my $foo = RHNC::Channel->new();
    ...

=head1 DESCRIPTION

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

my %entitlements = map { $_ => 1 }
  qw(monitoring_entitled provisioning_entitled virtualization_host virtualization_host_platform);

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
);

my %channel_type_for = (
    all      => 'listAllChannels',
    mine     => 'listMyChannels',
    popular  => 'listRedHatChannels',
    retired  => 'listRetiredChannels',
    shared   => 'listSharedChannels',
    software => 'listSoftwareChannels',
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

    my %v = map { $_ => 0 } ( keys %properties );

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

Returns the list of available arches, as a HASH ref ( C<label => name> ).

  my @arches_list = RHNC::Channel::list_arches($rhnc);
  my @arches_list = RHNC::Channel->list_arches($rhnc);
  my @arches_list = $channel->list_arches();

=cut

sub list_arches {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->list_arches
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::list_arches($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->list_arches($rhnc)
        $rhnc = shift @p;
    }
    else {
        confess "No RHNC client given here";
    }

    my $res = $rhnc->call("channel.software.listArches");

    my %arches = map { $_->{label} => $_->{name} } @{$res};
    $arch_ref = \%arches;
    return $arch_ref;
}

=head2 list_errata

Returns the list of errata for the channels specified.

  my @errata_list = RHNC::Channel::list_errata($rhnc, $channel);
  my @errata_list = RHNC::Channel->list_errata($rhnc, $channel);
  my @errata_list = $channel->list_errata();

=cut

sub list_errata {
    my ( $self, @p ) = @_;
    my $rhnc;
    my $id_or_name;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->list_errata
        $rhnc       = $self->{rhnc};
        $id_or_name = shift @p;
        if ( !defined $id_or_name ) {
            $id_or_name = $self->label();
        }
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::list_errata($rhnc)
        $rhnc       = $self;
        $id_or_name = shift @p;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->list_errata($rhnc)
        $rhnc       = shift @p;
        $id_or_name = shift @p;
    }
    else {
        confess "No RHNC client given here";
    }

    my $res = $rhnc->call( 'channel.software.listErrata', $id_or_name );

    my %errata = map { $_->{advisory} => $_ } @{$res};
    return %errata;
}

=head2 list_packages

Return the list of packages in the channel.

  $packages = $ch->list_packages();

=cut

sub list_packages {
    my ($self) = @_;

    if ( !defined $self->{list_packages} && defined $self->{rhnc} ) {
        $self->{list_packages} =
          $self->{rhnc}
          ->call( 'channel.software.listAllPackages', $self->label() );
        $self->{packages} = scalar( @{ $self->{list_packages} } );
    }

    return $self->{list_packages};
}

=head2 latest_packages

Returns the list of latest_packages for the channels specified.

  my $latest_packages = $channel->latest_packages();

=cut

sub latest_packages {
    my ($self) = @_;
    my $rhnc;
    my $id_or_name;

    if ( !defined $self->{latest_packages} && defined $self->{rhnc} ) {
        $self->{latest_packages} =
          $self->{rhnc}
          ->call( 'channel.software.listLatestPackages', $self->label() );
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
    my ( $self, @p ) = @_;
    my $rhnc;
    my $id_or_name;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->list_systems
        $rhnc       = $self->{rhnc};
        $id_or_name = shift @p;
        if ( !defined $id_or_name ) {
            $id_or_name = $self->label();
        }
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::list_systems($rhnc)
        $rhnc       = $self;
        $id_or_name = shift @p;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->list_systems($rhnc)
        $rhnc       = shift @p;
        $id_or_name = shift @p;
    }
    else {
        confess "No RHNC client given here";
    }

    my $res =
      $rhnc->call( 'channel.software.listSubscribedSystems', $id_or_name );

    my %systems = map { $_->{id} => $_->{name} } @{$res};
    return %systems;
}

=head2 name

Return channel name

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
    confess "Create $self->{label} did not work" if !defined $res;

    return $self;
}

=head2 destroy 

=cut

sub destroy {
    my ( $self, @args ) = @_;

    my $res = $self->{rhnc}->call( 'channel.software.delete', $self->label() );

    return $res;
}

=head2 list

List channels. Returns list of objects of type C<RHNC::Channel>.

  my @channel_list = RHNC::Channel::list($rhnc);
  my @channel_list = RHNC::Channel->list($rhnc);
  my @channel_list = $channel->list();

=cut

sub list {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        confess "No RHNC client given here";
    }

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

    my @l;
    foreach my $output ( keys %hres1 ) {
        my $c = __PACKAGE__->new( $hres1{$output} );
        $rhnc->manage($c);
        push @l, $c;
    }

    return @l;
}

=head2 get

Return detailled information about channel.

  my $chan  = RHNC::Channel::get( $rhnc, $label );  # $label or $id
  my $chan2 = RHNC::Channel->get( $rhnc, $label );  # $label or $id
  my $chan3 = $chan->get( $label );                 # $label or $id
  my $chan4 = $chan->get();                         # $label or $id

=cut

sub get {
    my ( $self, @p ) = @_;
    my $rhnc;
    my $id_or_name;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $channel->list
        $rhnc       = $self->{rhnc};
        $id_or_name = shift @p;
        if ( !defined $id_or_name ) {
            $id_or_name = $self->label();
        }
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::get($rhnc)
        $rhnc       = $self;
        $id_or_name = shift @p;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->get($rhnc)
        $rhnc       = shift @p;
        $id_or_name = shift @p;
    }
    else {
        confess "No RHNC client given";
    }

    if ( !defined $id_or_name ) {
        confess "No channel id or name specified in get";
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

Jérôme Fenal, C<< <jfenal at redhat.com> >>


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

Copyright 2009 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::Channel
