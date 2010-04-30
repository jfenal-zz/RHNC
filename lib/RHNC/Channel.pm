package RHNC::Channel;

# $Id$

use warnings;
use strict;
use Params::Validate;
use Carp;
use RHNC;
use Data::Dumper;

use vars qw( %properties %valid_prefix );
our @EXPORTS = qw( %properties );

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

my %arch_label = map { $_ => 1 } qw(
  channel-ia32    channel-ia64    channel-sparc   channel-alpha
  channel-s390    channel-s390x   channel-iSeries channel-pSeries
  channel-x86_64  channel-ppc     channel-sparc-sun-solaris
  channel-i386-sun-solaris);

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
    my $parm = shift;

    croak "Missing parameter $parm";
}

=head2 new
    
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
        croak "No RHNC client given here";
    }

    my $res = $rhnc->call("channel.software.listArches");

    my %arches = map { $_->{label} => $_->{name} } @{$res};
    return %arches;
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
        $rhnc = $self->{rhnc};
        $id_or_name = shift @p;
        if ( ! defined $id_or_name ) {
            $id_or_name = $self->label();
        }
        print "1\n";
    }
    elsif ( ref $self eq 'RHNC::Session' ) {
        # Called as RHNC::Channel::list_errata($rhnc)
        $rhnc = $self;
        $id_or_name = shift @p;
        print "2\n";
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {
        # Called as RHNC::Channel->list_errata($rhnc)
        $rhnc = shift @p;
        $id_or_name = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }

    my $res = $rhnc->call('channel.software.listErrata', $id_or_name );

    my %errata = map { $_->{advisory} => $_ } @{$res};
    return %errata;
}

=head2 name

  $name = $ch->name;

=cut

sub name {
    my ( $self, @p ) = @_;

    if ( !defined $self->{name} ) {
        croak 'name not defined';
    }

    return $self->{name};
}

=head2 label

  $label = $ch->label;

=cut

sub label {
    my ( $self, @p ) = @_;

    if ( !defined $self->{label} ) {
        croak 'label not defined';
    }

    return $self->{label};
}

=head2 parent_label

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

  $arch = $ch->arch;

=cut

sub arch {
    my ( $self, @p ) = @_;

    if ( ! defined $self->{arch} ) {
        if ( defined $self->{arch_name}) {
            $self->{arch} = $self->{arch_name};
        }
        else {
            croak "Arch not defined for this channel $self->{label}";
        }
    }

    return $self->{arch};
}

=head2 provider_name

  $provider_name = $ch->provider_name;

=cut

sub provider_name {
    my ( $self, @p ) = @_;

    if ( defined $self->{provider_name} ) {
        return $self->{provider_name};
    }

    return;
}

=head2 packages

Return the packages in the channel.

  $packages = $ch->packages();

=cut

sub packages {
    my ( $self, @p ) = @_;

    if ( ! defined $self->{packages} ) {
        $self->{packages} = $self->{rhnc}->call( 'channel.software.listAllPackages', $self->label() );
    }
    $self->{nbpackages} = scalar (@{$self->{packages}}) ;

    return @{$self->{packages}};
}


=head2 nbpackages

Return number of packages in the channel.

  $nbpackages = $ch->nbpackages();

=cut

sub nbpackages {
    my ( $self, @p ) = @_;

    if ( ! defined $self->{nbpackages} ) {
        $self->packages();
    }

    return $self->{nbpackages};
}



=head2 systems

  $systems = $ch->systems;

=cut

sub systems {
    my ( $self, @p ) = @_;

    if ( defined $self->{systems} ) {
        return $self->{systems};
    }

    return;
}

=head2 create

=cut

sub create {
    my ( $self, @args ) = @_;

    if ( !ref $self ) {
        $self = __PACKAGE__->new(@args);
    }

    foreach my $p (qw( )) {
        if ( !defined $self->{$p} ) {
            _missing_parameter($p);
        }
    }

    croak 'No RHNC client to persist to, exiting'
      if !defined $self->{rhnc};

    my $res =
      $self->{rhnc}
      ->call( 'channel.software.create', $self->{label}, $self->{name},
        $self->{summary}, $self->{arch_name}, $self->{parent_channel_label},
      );
    croak 'Create did not work' if !defined $res;
    $self->{key} = $res;

    return $self;
}

=head2 destroy 

=cut

sub destroy {
    my ( $self, @args ) = @_;

    my $res = $self->{rhnc}->call( 'activationkey.delete', $self->{key} );

    undef $self;

    return 1;
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
        croak "No RHNC client given here";
    }

    my $q = shift @p;
    my $call;
    if ( defined $q && defined $channel_type_for{$q} ) {
        $call = $channel_type_for{$q};
    }
    else {
        $call = $channel_type_for{software};
    }

    my $res = $rhnc->call("channel.$call");

    #    print STDERR Dumper($res);

    my @l;
    foreach my $output (@$res) {
        my $c = __PACKAGE__->new($output);
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
        $rhnc = $self->{rhnc};
        $id_or_name = shift @p;
        if ( ! defined $id_or_name ) {
            $id_or_name = $self->label();
        }
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::get($rhnc)
        $rhnc = $self;
        $id_or_name = shift @p
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Channel->get($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given";
    }

    if (! defined $id_or_name) {
        croak "No channel id or name specified in get";
    }        

    my $res = $rhnc->call( 'channel.software.getDetails', $id_or_name );

    my $channel = __PACKAGE__->new( %{$res} );

    $rhnc->manage($channel);

    return $channel;
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
