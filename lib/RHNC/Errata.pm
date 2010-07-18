#
# This package is just a template for future modules in the RHNC
# namespace. It is not supposed to deliver a specific purpose in the
# RHNC context
#
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

Quick summary of what the module does.

Perhaps a little code snippet.

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

    return $self;
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

Jérôme Fenal, C<< <jfenal at redhat.com> >>

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

Copyright 2009 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of RHNC::Errata
