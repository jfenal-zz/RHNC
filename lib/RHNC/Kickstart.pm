package RHNC::Kickstart;

# $Id$

use warnings;
use strict;
use Params::Validate;
use Carp;
use Data::Dumper;

use base qw( RHNC );

use vars qw( %properties %virt_type %advanced_options );

%advanced_options = map { $_ => 1 } qw(
  autostep interactive install upgrade text network cdrom
  harddrive nfs url lang langsupport keyboard mouse device
  deviceprobe zerombr clearpart bootloader timezone auth rootpw selinux
  reboot firewall xconfig skipx key ignoredisk autopart cmdline firstboot
  graphical iscsi iscsiname logging monitor multipath poweroff
  halt service shutdown user vnc zfcp
);

=head1 NAME

RHNC::Kickstart - Red Hat Network Client - Kickstart handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::Kickstart;

    my $foo = RHNC::Kickstart->new();
    ...

=head1 DESCRIPTION

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %properties = (
    rhnc          => [ 0, undef, undef, undef ],
    label         => [ 1, undef, undef, undef ],
    name          => [ 0, undef, undef, undef ],
    server        => [ 1, undef, undef, undef ],
    tree_label    => [ 1, undef, undef, undef ],
    password      => [ 1, undef, undef, undef ],
    org_default   => [ 0, undef, undef, undef ],
    advanced_mode => [ 0, undef, undef, undef ],
    active        => [ 0, undef, undef, undef ],
    virt_type     => [
        1, 'none',
        sub {
            my $v = shift;
            return 1 if defined $virt_type{$_};
            return 0;
        },
        undef
    ],
);

our %virt_type = map { $_ => 1 } qw( none para_host qemu  xenfv xenpv);

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


=head2 _uniqueid

Return kickstart _uniqueid (label).

    $uuid = $ks->_uniqueid;

=cut

sub _uniqueid {
    my ( $self ) = @_;
    return $self->{label};
}


=head2 new

Create a new RHNC::Kickstart object.

  my $ks = RHNC::Kickstart->new(
      rhnc       => $rhnc,
      label      => 'new-ks',
      name       => 'new-ks',
      server     => $rhnc->server(),
      tree_label => 'ks-rhel-x86_64-server-5-u4',
      virt_type  => 'none',
      password   => 'redhat',
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

    if (  !defined $self->{server}
        && defined( $self->{rhnc} )
        && defined $self->{rhnc}->name() )
    {
        $self->{server} = $self->{rhnc}->name();
    }

    return $self;
}

=head2 child_channels

Return kickstart child channels

  my $name = $ks->child_channels();

=cut

sub child_channels {
    my ( $self, @p ) = @_;

    if ( !defined $self->{child_channels} ) {
        croak 'child_channels not defined';
    }

    return $self->{child_channels};
}

=head2 name

Return kickstart name

  my $name = $ks->name();

=cut

sub name {
    my ( $self, @p ) = @_;

    if ( !defined $self->{name} ) {
        if ( defined $self->{label} ) {
            $self->{name} = $self->{label};
        }
        else {
            croak 'name not defined';
        }
    }

    return $self->{name};
}

=head2 label

Return kickstart label

  my $name = $ks->label();

=cut

sub label {
    my ( $self, @p ) = @_;

    if ( !defined $self->{label} ) {
        croak 'label not defined for kickstart' . Dumper($self) . "\n";
    }

    return $self->{label};
}

=head2 tree_label

Return kickstart's tree_label.

  my $org = $ks->tree_label();

=cut

sub tree_label {
    my ( $self, @p ) = @_;

    if ( !defined $self->{tree_label} ) {
        croak "tree_label not defined for kickstart $self->{label}";
    }

    return $self->{tree_label};
}

=head2 org_default

Return true if kickstart is default for current Organization, false
otherwise..

  my $org = $ks->org_default();

=cut

sub org_default {
    my ( $self, @p ) = @_;

    if ( !defined $self->{org_default} ) {
        croak 'org_default not defined';
    }

    return $self->{org_default}->value;
}

=head2 active

Return true if kickstart is active, false otherwise.

  my $org = $ks->active();

=cut

sub active {
    my ( $self, @p ) = @_;

    if ( !defined $self->{active} ) {
        croak 'active not defined';
    }

    return $self->{active}->value();
}

=head2 virt_type

Getter/(setter TODO) for virt_type.

  my $org = $ks->virt_type();

BUG: currently, no call exists to retrieve this information.

=cut

sub virt_type {
    my ( $self, @p ) = @_;

    if ( !defined $self->{virt_type} ) {
        croak 'virt_type not defined';
    }

    return $self->{virt_type};
}

=head2 advanced_mode

Return true if kickstart is defined with advanced_mode, false
otherwise.

  my $advanced_mode = $ks->advanced_mode();

=cut

sub advanced_mode {
    my ( $self, @p ) = @_;

    if ( !defined $self->{advanced_mode} ) {
        croak 'advanced_mode not defined';
    }

    return $self->{advanced_mode}->value;
}

=head2 advanced_options

Return (and/or populate inside the C<$ks> object) a table of advanced
options for the kickstart.

  my @advanced_options = $ks->advanced_options();

=cut

sub advanced_options {
    my ( $self, @p ) = @_;
    my @ao;

    if ( !defined $self->{advanced_options} ) {
        my $res =
          $self->{rhnc}
          ->call( 'kickstart.profile.getAdvancedOptions', $self->name() );
        $self->{advanced_options} = $res;
    }

    return $self->{advanced_options};
}

=head2 custom_options

Return (and/or populate inside the C<$ks> object) a table of custom
options for the kickstart.

  my @custom_options = $ks->custom_options();

=cut

sub custom_options {
    my ( $self, @p ) = @_;
    my @ao;

    if ( !defined $self->{custom_options} ) {
        my $res =
          $self->{rhnc}
          ->call( 'kickstart.profile.getCustomOptions', $self->name() );
        $self->{custom_options} = $res;
    }

    return $self->{custom_options};
}

=head2 variables

Return (and/or populate inside the C<$ks> object) a table of variables
for the kickstart.

  my @variables = $ks->variables();

=cut

sub variables {
    my ( $self, @p ) = @_;
    my @ao;

    if ( !defined $self->{variables} ) {
        my $res =
          $self->{rhnc}
          ->call( 'kickstart.profile.getVariables', $self->name() );
        $self->{variables} = $res;
    }

    return $self->{variables};
}

=head2 create

Create and persist a new kickstart from scratch, or from an existing one.

=cut

sub create {
    my ( $self, @args ) = @_;

    if ( !ref $self ) {
        $self = __PACKAGE__->new(@args);
    }

    croak 'No RHNC client to persist to, exiting'
      if !defined $self->{rhnc};

    my $res =
      $self->{rhnc}
      ->call( 'kickstart.createProfile', $self->{label}, $self->{virt_type},
        $self->{tree_label}, $self->{server}, $self->{password}, );
    croak 'Create did not work' if !defined $res;

    if ( defined $res ) {
        $self->{rhnc}->manage($self);
    }

    return $self;
}

=head2 destroy 

OO context: 

  $ks->destroy();

Function context:

  RHNC::Kickstart::destroy( $rhnc, $ksname );

=cut

sub destroy {
    my ( $self, @args ) = @_;

    my $rhnc;
    my $ksname;
    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {    # OO context
        $rhnc   = $self->{rhnc};
        $ksname = $self->{label};
        undef $self;
    }
    elsif ( ref $self eq 'RHNC::Session' ) {    # package context
        $rhnc   = $self;
        $ksname = shift @args;
    }
    else {
        croak "No RHNC client given here";
    }

    my $res = $rhnc->call( 'kickstart.deleteProfile', $ksname );

    return 1;
}

=head2 list

Return the list of available L<RHNC::Kickstart> objects.

  my @ks_list = RHNC::Kickstart::list( $rhnc );
  my @ks_list = RHNC::Kickstart->list( $rhnc );
  my @ks_list = $ks->list();

=cut

sub list {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::Kickstart' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Kickstart::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::Kickstart->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }

    my $res = $rhnc->call('kickstart.listKickstarts');

    #    print STDERR Dumper $res;

    my $l = [];
    foreach my $o (@$res) {
        push @$l, __PACKAGE__->new($o);
    }

    return $l;
}

=head2 get

Get (populate) complete kickstart profile.

  my $ks1 = $ks->get();
  my $ks2 = RHNC::Kickstart->get();
  my $ks3 = RHNC::Kickstart::get();

=cut

sub get {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ks->list()
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::Kickstart::get($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ ) {

        # Called as RHNC::Kickstart->get($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given";
    }

    my $name = shift @p
      or croak "No kickstart name specified in get";

    # Step 1:
    # Get base information from listKickstart
    my $res = $rhnc->call('kickstart.listKickstarts');

    my $found = 0;
    foreach my $ks ( @{$res} ) {

        #        print Dumper $k;
        #        print "label: $k->{label}\n";
        if ( $ks->{label} eq $name ) {
            $found = 1;
            if ( ref $self ne __PACKAGE__ ) {
                $self = __PACKAGE__->new( %{$ks} );
                $rhnc->manage($self);
            }

            foreach my $k ( keys %{$ks} ) {
                $self->{$k} = $ks->{$k};
            }
        }
    }
    if ( $found == 0 ) {
        carp "No kickstart named $name found";
        return;
    }

    # TODO : Step 2:
    # Get kickstart_tree (TODO : check if not already given by Step 1).

    # TODO : Step 3:
    # Get channels
    $res = $rhnc->call( 'kickstart.profile.getChildChannels', $self->label() );
    $self->{child_channels} = $res;

    # TODO : Step 4:
    # Get advanced options
    $self->advanced_options();

    # TODO : Step 5:
    # Get Custom options
    $self->custom_options();

    # TODO : Step 6:
    # Get Variables
    $self->variables();

    # TODO : Step 7:
    # Get Profile options :
    # - Locale
    # - Partitioning scheme
    # - SELinux
    # - ConfigManagement
    # - RemoteCommands
    # - FilePreservationList

    return $self;
}

=head2 as_string

Returns a printable string to describe the kickstart.

  print $ks->as_string;


=cut

sub as_string {
    my ($self) = @_;
    my $str;

    $str = $self->name . ":\n";
    foreach my $k ( sort ( keys %{$self} ) ) {
        next if $k eq 'rhnc';
        if ( defined $self->{$k} ) {
            $str .= "  $k: $self->{$k}\n";
        }
    }

    return $str;

}

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 AUTHOR

Jerome Fenal, L<jfenal@free.fr>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Kickstart


You can also look for information at:

=over 4

=item *

RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RHNC-Session>

=item *

AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RHNC-Session>

=item *

CPAN Ratings

L<http://cpanratings.perl.org/d/RHNC-Session>

=item *

Search CPAN

L<http://search.cpan.org/dist/RHNC-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2009,2010 Jerome Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::Kickstart
