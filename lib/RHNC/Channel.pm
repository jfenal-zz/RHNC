package RHNC::Channel;

# $Id$

use warnings;
use strict;
use Params::Validate;
use Carp;
use RHNC;
use Data::Dumper;

use base qw( RHNC );

use vars qw( %properties %valid_prefix );

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
    parent_channel_label => [ 1, q(),   undef, undef ],
    id                   => [ 0, undef, undef, undef ],
    provider_name        => [ 0, undef, undef, undef ],
    packages             => [ 0, undef, undef, undef ],
    systems              => [ 0, undef, undef, undef ],
    arch_name            => [ 1, undef, undef, undef ],
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
        label -> "label",
        name -> "name",
        summary -> "summary",
        archLabel -> "summary", # arch_name in structure from getDetails
        parentLabel -> "parent-label",
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

Return number of packages in the channel.

  $packages = $ch->packages;

=cut

sub packages {
    my ( $self, @p ) = @_;

    if ( defined $self->{packages} ) {
        return $self->{packages};
    }

    return;
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

=cut

sub list {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::Channel' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
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
        $call = $channel_type_for{all};
    }

    my $res = $rhnc->call("channel.$call");

    print STDERR Dumper($res);
    my @l;
    foreach my $o (@$res) {
        push @l, RHNC::Channel->new($o);
    }

    return @l;
}

=head2 get

=cut

sub get {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::Channel' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Channel::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ ) {

        # Called as RHNC::Channel->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given";
    }

    my $k = shift @p
      or croak "No activation key specified in get";

    my $res = $rhnc->call( 'activationkey.getDetails', $k );

    my $ak = __PACKAGE__->new( %{$res} );

    $rhnc->manage($ak);

    return $ak;
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
