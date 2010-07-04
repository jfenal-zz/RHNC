package RHNC::Package;

use warnings;
use strict;
use Params::Validate;
use Data::Dumper;
use Carp;

use base qw( RHNC );
use vars qw( %properties %arch_canon );

=head1 NAME

RHNC::Package - Red Hat Network Client - Package handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::Package;

    my $foo = RHNC::Package->new();
    ...

=head1 EXPORT

None.
L<is_packageid> is to be referenced by its full name.

=head1 SUBROUTINES/METHODS

=cut

=head2 is_packageid

Returns true if package id B<looks> valid, false otherwise.

=cut

sub is_packageid {
    my ($s) = shift;
    return 1 if $s =~ m{ \A \d+ \z }imxs;
    return 0;
}

use constant rpmrc => '/usr/lib/rpm/rpmrc';

my %arch_canon = (
    map { $_ => 1 }
      qw( noarch athlon geode pentium4 pentium3 i686 i586 i486 i386 x86_64
      amd64 ia32e alpha alphaev5 alphaev56 alphapca56 alphaev6 alphaev67
      sparc64 sun4u sparc64v sparc sun4 sun4m sun4c sun4d sparcv8 sparcv9 sparcv9v
      mips ppc ppc8260 ppc8560 ppc32dy4 ppciseries ppcpseries m68k IP rs6000
      ia64 mipsel armv3l armv4b armv4l armv5tel armv5tejl armv6l armv7l
      m68kmint atarist atariste ataritt falcon atariclone milan hades
      s390 i370 s390x
      ppc64 ppc64pseries ppc64iseries
      sh sh3 sh4 sh4a xtensa)
);

=head2 list_arch_canon

  @list_arch = RHNC::Package::list_arch_canon;
  @list_arch = RHNC::Package::list_arch_canon( 1 ); # update list from rpmrc

Get the list of canonical arches, as they are need to split a package
name.

=cut

sub list_arch_canon {
    my ($update) = @_;
    my $list = [];
    if ( defined $update && $update && -f rpmrc ) {
        open my $f, '<', rpmrc
          or croak "Cannot open for read list of canonical arches" . rpmrc;

        @$list = ('noarch');
        while ( my $l = <$f> ) {
            chomp $l;
            if ( $l =~ m{ \A arch_canon : \s* ([^\s:]+) \s* :  }imxs ) {
                push @$list, $1;
            }
        }
        close $f or croak "Cannot close list of canonical arches" . rpmrc;

        %arch_canon = map { $_ => 1 } @$list;
    }
    else {
        @$list = keys %arch_canon;
    }

    return $list;
}

=head2 split_package_name

  ( $name, $version, $release, $arch ) = split_package_name( 'kernel-doc-2.6.33.5-124.fc13.noarch' );
  ( $name, $version, $release ) = split_package_name( 'kernel-doc-2.6.33.5-124.fc13' );

=cut

sub split_package_name {
    my ($p) = @_;

    my $qrarch = '\.(' . join( '|', keys %arch_canon ) . ')$';
    $qrarch = qr($qrarch);

    my ( $name, $version, $release, $arch );

    my @c;
    @c = split /\./, $p;
    if ( defined $arch_canon{ $c[-1] } ) {
        $arch = pop @c;
    }
    $p = join '.', @c;

    @c = split /-/, $p;
    if (   defined $c[-1]
        && defined $c[-2]
        && $c[-1] =~ m{ \A \d .* }imxs
        && $c[-2] =~ m{ \A \d .* }imxs )
    {
        $release = pop @c;
        $version = pop @c;
    }

    $name = join '-', @c;

    return ( $name, $version, $release, $arch );
}

=head2 join_package_name

  $pname = join_package_name($name);
  $pname = join_package_name( $name, $version, $release );
  $pname = join_package_name( $name, $version, $release, $arch );

=cut

sub join_package_name {
    my ($h) = @_;
    my $pname;

    croak "No package name to join in a package full name"
      if not defined $h->{name};
    $pname = $h->{name};

    if ( defined $h->{version} && defined $h->{release} ) {
        $pname .= "-$h->{version}-$h->{release}";
    }
    if ( defined $h->{arch} && defined $arch_canon{ $h->{arch} } ) {
        $pname .= ".$h->{arch}";
    }

    return $pname;
}

#
# Methods
#
use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %properties = (
    id                 => [ 0, undef, undef, undef ],
    name               => [ 1, undef, undef, undef ],
    version            => [ 1, undef, undef, undef ],
    release            => [ 1, undef, undef, undef ],
    epoch              => [ 0, undef, undef, undef ],
    arch_label         => [ 1, undef, undef, undef ],
    path               => [ 0, undef, undef, undef ],
    provider           => [ 0, undef, undef, undef ],
    last_modified      => [ 0, undef, undef, undef ],
    file               => [ 0, undef, undef, undef ],
    vendor             => [ 0, undef, undef, undef ],
    last_modified_date => [ 0, undef, undef, undef ],
    license            => [ 0, undef, undef, undef ],
    providing_channels => [ 0, undef, undef, undef ],
    size               => [ 0, undef, undef, undef ],
    payload_size       => [ 0, undef, undef, undef ],
    description        => [ 0, undef, undef, undef ],
    path               => [ 0, undef, undef, undef ],
    summary            => [ 0, undef, undef, undef ],
    cookie             => [ 0, undef, undef, undef ],
    md5sum             => [ 0, undef, undef, undef ],
    build_date         => [ 0, undef, undef, undef ],
    build_host         => [ 0, undef, undef, undef ],
    rhnc               => [ 0, undef, undef, undef ],
);

=head2 new

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    bless $self, $class;

    my %v = map { $_ => 0 } ( keys %properties );

    my %p = validate( @args, \%v );

    for my $i ( keys %properties ) {
        $self->{$i} = $p{$i};
    }

    if ( defined $self->{rhnc} ) {
        $self->{rhnc}->manage($self);
    }

    return $self;
}

=head2 id

Return package id

=cut

sub id {
    my ($self) = @_;

    return $self->{id};
}

=head2 nvra

Return package full name (NVRA).

=cut

sub nvra {
    my ($self) = @_;

    return
      "$self->{name}.$self->{version}.$self->{release}.$self->{arch_label}";
}

=head2 name

Return package name.

=cut

sub name {
    my ($self) = @_;

    return $self->{name};
}

=head2 version

Return package version.

=cut

sub version {
    my ($self) = @_;

    return $self->{version};
}

=head2 release

Return package release.

=cut

sub release {
    my ($self) = @_;

    return $self->{release};
}

=head2 arch

Return package arch

=cut

sub arch {
    my ($self) = @_;

    return $self->{arch_label};
}

=head2 get

=cut

sub get {
    my ( $self, @p ) = @_;
    my $rhnc;
    my $id_or_name;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->get
        $rhnc       = $self->{rhnc};
        $id_or_name = $self->{id};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::SystemGroup::get($rhnc)
        $rhnc       = $self;
        $id_or_name = shift @p;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::SystemGroup->get($rhnc)
        $rhnc       = shift @p;
        $id_or_name = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }

    if ( !defined $id_or_name ) {
        croak "No package id or name given";
    }

    if ( !is_packageid($id_or_name) ) {
        my $p = RHNC::Package->search( $rhnc, split_package_name($id_or_name) );
        $id_or_name = $p->id;
    }

    my $res = $rhnc->call( 'packages.getDetails', $id_or_name );

    my $p = RHNC::Package->new(
        rhnc => $rhnc,
        %$res,
    );

    return $p;
}

=head2 search

Search a package by NVREA.

    $p =
      RHNC::Package::search( $rhnc, $name, $version, $release, $arch );
    $p =
      RHNC::Package->search( $rhnc, $name, $version, $release, $arch );
    $p = $opkg->search( $name, $version, $release, $arch );

=cut

sub search {
    my ( $self, @p ) = @_;
    my ($rhnc);

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ch->get
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::SystemGroup::get($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::SystemGroup->get($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }
    my $name    = shift @p;
    my $version = shift @p;
    my $release = shift @p;
    my $arch    = shift @p;
    my $epoch   = q();        #shift @p;

    my $res = $rhnc->call( 'packages.findByNvrea',
        $name, $version, $release, $epoch, $arch );

    if ( defined $res && scalar(@$res) == 1 ) {
        my $p = RHNC::Package->get( $rhnc, $res->[0]{id} );

        return $p;
    }
    else {
        return;
    }

}

=head2 url

Return the URL to download the package. This URL will expire after a
certain time period. 

=cut

sub url {
    carp "Not implemented";
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

    perldoc RHNC::Package


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

1;    # End of RHNC::Package
