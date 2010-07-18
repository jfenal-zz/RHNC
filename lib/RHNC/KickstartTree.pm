package RHNC::KickstartTree;

# $Id$

use warnings;
use strict;
use Params::Validate;
use Carp;
use Data::Dumper;

use base qw( RHNC );

use vars qw( %properties %virt_type );

=head1 NAME

RHNC::KickstartTree - Red Hat Network Client - Manage RHN Satellite
Kickstart trees

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::KickstartTree;

    my $foo = RHNC::KickstartTree->new();
    ...

=head1 SUBROUTINES/METHODS

my %entitlements = map { $_ => 1 }
  qw(monitoring_entitled provisioning_entitled virtualization_host virtualization_host_platform);

=cut

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %properties = (
    rhnc       => [ 0, undef, undef, undef ],
    label      => [ 1, undef, undef, undef ],
    server     => [ 1, undef, undef, undef ],
    tree_label => [ 1, undef, undef, undef ],
    password   => [ 1, undef, undef, undef ],
    virt_type  => [
        1, 'none',
        sub {
            my $v = shift;
            return 1 if defined $virt_type{$_};
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

=head2 _uniqueid

Return kickstart tree key _uniqueid (label).

    $uuid = $kst->_uniqueid;

=cut

sub _uniqueid {
    my ( $self ) = @_;
    return $self->{label};
}


=head2 new

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

    if ( !defined $self->{server} ) {
        $self->{server} = $self->{rhnc}->name();
    }

    # FIXME : pas la bonne façon de savoir si on veut les créer...
    # peut-être pas la chose à faire par défaut, même...
    if ( defined $self->{rhnc} ) {
        $self->create();
        $self->{rhnc}->manage($self);
    }

    return $self;
}

=head2 name

=cut

sub name {
    my ( $self, @p ) = @_;

    if ( !defined $self->{tree_label} ) {
        croak 'tree_label not defined';
    }

    return $self->{tree_label};
}

=head2 tree_label

=cut

sub tree_label {
    my ( $self, @p ) = @_;

    if ( !defined $self->{tree_label} ) {
        croak 'tree_label not defined';
    }

    return $self->{tree_label};
}

=head2 create

=cut

sub _missing_parameter {
    my $parm = shift;

    croak "Missing parameter $parm";
}

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

    my $res = $self->{rhnc}->call(
        'kickstart.tree.create', $self->{tree_label},
        $self->{base_path},      $self->{channel_label},
        $self->{install_type},
    );
    croak 'Create did not work' if !defined $res;

    $self->{tree_label} = $res;

    return $self;
}

=head2 destroy 

=cut

sub destroy {
    my ( $self, @args ) = @_;

    my $res = $self->{rhnc}->call( 'kickstart.tree.delete', $self->{key} );

    undef $self;

    return 1;
}

=head2 list

=cut

sub list {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::KickstartTree' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::KickstartTree::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::KickstartTree->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }

    my $res = $rhnc->call('kickstart.tree.list');

    #    print STDERR Dumper($res);
    my $l = [];
    foreach my $o (@$res) {
        push @$l, RHNC::KickstartTree->new($o);
    }

    return $l;
}

=head2 get

=cut

sub get {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::KickstartTree' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::KickstartTree::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ ) {

        # Called as RHNC::KickstartTree->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given";
    }

    my $k = shift @p
      or croak "No kickstart tree label specified in get";

    my $res = $rhnc->call( 'kickstart.tree.getDetails', $k );

    my $ak = __PACKAGE__->new( %{$res} );

    $rhnc->manage($ak);

    return $ak;
}

=head2 list_install_types

=cut

sub list_install_types {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq 'RHNC::KickstartTree' && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::KickstartTree::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ ) {

        # Called as RHNC::KickstartTree->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given";
    }

    my $res = $rhnc->call('kickstart.tree.listInstallTypes');

    return $res;
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

    perldoc RHNC::KickstartTree


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

1;    # End of RHNC::KickstartTree
