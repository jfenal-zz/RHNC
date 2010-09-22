package RHNC::Errata;

use warnings;
use strict;
use Params::Validate;
use Carp;
use base qw( RHNC );

=head1 NAME

RHNC::Errata - Red Hat Network Client - Errata handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS


    use RHNC::Errata;

    my $foo = RHNC::Errata->new();
    ...

=head1 SUBROUTINES/METHODS

=cut

our %errata_type = (
    RHSA => 'Security Advisory',
    RHBA => 'Bug Fix Advisory',
    RHEA => 'Product Enhancement Advisory',
    s    => 'Security Advisory',
    b    => 'Bug Fix Advisory',
    e    => 'Product Enhancement Advisory',
    bug  => 'Security Advisory',
    sec  => 'Bug Fix Advisory',
    enh  => 'Product Enhancement Advisory',
);

=head2 _uniqueid

Return errata _uniqueid (id).

    $uuid = $e->_uniqueid;

=cut

sub _uniqueid {
    my ( $self ) = @_;
    return $self->{id};
}

=head2 new

Create a new C<RHNC::Errata> object.

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    bless $self, $class;

    %$self = @args;

    return $self;
}


=head2 get

Get details about a C<RHNC::Errata> object.

=cut

sub get {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );
    my $id_or_name = shift @args;

    croak "No errata id given" if !defined $id_or_name;

    my $res = $rhnc->call( 'errata.getDetails', $id_or_name );

    if (defined $res) {
        my $e = __PACKAGE__->new( rhnc => $rhnc, name => $id_or_name, %$res);
        return $e;
    }

    return;
}


=head2 create

Create a new errata from an errata object

C<rhnc> attribute will have to be defined.

=cut

sub create {

}


=head2 publish

Publish a created errata.

=cut

sub publish {

}


#
# Getters & setters
#

=head2 synopsis

Return synopsis for erratum

  print $errata->synopsis();

=cut
sub synopsis {
    my ($self) = @_;

    return $self->{description};
}


=head2 advisory_name

Return advisory_name for erratum

  print $errata->advisory_name();

=cut
sub advisory_name {

}


=head2 advisory_release

Return advisory_release for erratum

  print $errata->advisory_release();

=cut
sub advisory_release {}


=head2 advisory_type

Return advisory_type for erratum

  print $errata->advisory_type();

=cut
sub advisory_type {
    #" - Type of advisory (one of the following: 'Security Advisory', 'Product Enhancement Advisory', or 'Bug Fix Advisory'
}



=head2 product

Return product for erratum

  print $errata->product();

=cut
sub product {
}


=head2 topic

Return topic for erratum

  print $errata->topic();

=cut
sub topic {
}


=head2 description

Return description for erratum

  print $errata->description();

=cut
sub description {
}


=head2 references

Return references for erratum

  print $errata->references();

=cut
sub references {
}


=head2 notes

Return notes for erratum

  print $errata->notes();

=cut
sub notes {
}


=head2 solution

Return solution for erratum

  print $errata->solution();

=cut
sub solution {
}



=head2 cve

Get CVE list for given errata as an array ref.

  @cves = @{ $errata->cve() };

=cut

sub cve {
    my ( $self) = @_;

    my $res = $self->{rhnc}->call( 'errata.listCves', $self->name() );

    if (defined $res) {
        return $res;
    }

    return;
}


=head2 findByCve

Search errata by CVE id.

Returns a array ref to the list of corresponding errata.

  my @errata = RHNC::Errata::cve( $rhnc, $cve_id );
  my @errata = RHNC::Errata->cve( $rhnc, $cve_id );

=cut

sub findByCve {
    my ( $self, $rhnc, @args ) = RHNC::_get_self_rhnc_args( __PACKAGE__, @_ );
    my $id_or_name = shift @args;

    croak "No errata id given" if !defined $id_or_name;

    my $res = $rhnc->call( 'errata.findByCve', $id_or_name );

    my @errata;
    foreach my $e ( @$res ) {
        push @errata, __PACKAGE__->new( rhnc => $rhnc, %$e);
    }

    return \@errata;
}


=head2 as_string

Return a printable string describing the erratum.

  print $e->as_string;

=cut

sub as_string {
    my ($self) = @_;
    my $str;
    foreach my $k ( sort ( keys %{$self} ) ) {
        if ( !ref $self->{$k} && $self->{$k} ne q() ) {
            my $e = $self->{$k};
            $e =~ s/[\n\r]/,/g;
            $str .= " $k: $e\n";
        }
    }
    return $str;
}

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 AUTHOR

Jerome Fenal, C<< <jfenal at free.fr> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Errata


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

1; # End of RHNC::Errata
