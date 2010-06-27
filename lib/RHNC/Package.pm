package RHNC::Package;

use warnings;
use strict;
use Params::Validate;
use Carp;

use base qw( RHNC );
use vars qw( $AUTOLOAD %properties %valid_prefix );

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

=head1 METHODS

=cut

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %properties = (
    id            => [ 0, undef, undef, undef ],
    name          => [ 1, undef, undef, undef ],
    version       => [ 1, undef, undef, undef ],
    release       => [ 0, undef, undef, undef ],
    epoch         => [ 0, undef, undef, undef ],
    arch_label    => [ 0, undef, undef, undef ],
    path          => [ 0, undef, undef, undef ],
    provider      => [ 0, undef, undef, undef ],
    last_modified => [ 0, undef, undef, undef ],
    rhnc          => [ 0, undef, undef, undef ],
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

=head2 get

=cut

sub get {
    my ( $self, @p ) = @_;
    my $rhnc;

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
    my $id = shift @p;

    my $res = $rhnc->call( 'package.getDetails', $id );

    my $p = RHNC::Package->new(
        rhnc => $rhnc,
        %$res,
    );

    return $p;
}

=head2 search

Search a package by NVREA.

    $p =
      RHNC::Package::search( $rhnc, $name, $version, $release, $epoch, $arch );
    $p =
      RHNC::Package->search( $rhnc, $name, $version, $release, $epoch, $arch );
    $p = $opkg->search( $name, $version, $release, $epoch, $arch );

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
    my $epoch   = shift @p;
    my $arch    = shift @p;

    my $res = $rhnc->call( 'package.findByNvrea',
        $name, $version, $release, $epoch, $arch );

    if ( defined $res ) {
        my $p = RHNC::Package->new( rhnc => $rhnc, %$res );

        return $p;
    }
    else {
        return;
    }

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
