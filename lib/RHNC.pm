package RHNC;

# $Id$
# $Revision$

use warnings;
use strict;
use vars qw(  %_properties );

use Params::Validate;
use Carp;

use Frontier::Client;
use RHNC::Session;
use RHNC::ActivationKey;
use RHNC::Errata;
use RHNC::Kickstart;
use RHNC::KickstartTree;
use RHNC::Org;
use RHNC::Package;
use RHNC::System;
use RHNC::SystemGroup;
use RHNC::Channel;
use RHNC::ConfigChannel;
use RHNC::System::CustomInfo;

our $_xmlfalse = Frontier::RPC2::Boolean->new(0);
our $_xmltrue  = Frontier::RPC2::Boolean->new(1);

our @EXPORTS = qw( $VERSION $_xmlfalse $_xmltrue);

=head1 NAME

RHNC - An OO Red Hat Network Satellite Client.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC;

    my $foo = RHNC->new();
    ...

=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=cut

sub _bool {
    my ($arg) = @_;

    return $arg ? $_xmltrue : $_xmlfalse;
}

=head2 new

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    bless $self, $class;

    return $self;
}

=head2 manage($object)

Manage C<$object> using RHNC. Allows persistance of such objects, if
not already created.

$object must be blessed in 'RHNC::*' namespace.

=cut

sub manage {
    my ( $self, $object ) = @_;

    if ( !defined $object ) {
        croak 'Can\'t manage undefined object';
    }
    if ( ref $object !~ m{ \A RHNC:: }imxs ) {
        carp 'Can\'t manage this class of objects : ' . ref $object;
        return;
    }

    $object->{rhnc} = $self;

    my $uid = $object->_uniqueid;
    if ( !defined $uid || $uid eq q{} ) {
        croak 'Object unique id not defined';
    }

    $self->{_managed}{$uid} = \$object;

    return $self;
}

=head2 unmanage( $obj )

Remove a specified object from list of managed object. Remove cross
references.

=cut

sub unmanage {
    my ( $self, $object ) = @_;

    if ( ref $object !~ m{ \A RHN:: }imxs ) {
        return;
    }

    delete $self->{_managed}{ $object->name() };
    delete $object->{rhnc};

    return $self;
}

=head2 save()

Save all unsaved objects

=cut

sub save {
    my ($self) = @_;

    foreach my $o ( keys %{ $self->{_managed} } ) {
        $o->save();
    }

    return $self;
}

=head2 rhnc()

Return corresponding RHN Client, if available.

=cut

sub rhnc {
    my ( $self, $rhnc ) = @_;

    if ( defined $rhnc ) {
        $self->{rhnc} = $rhnc;
    }
    return $self->{rhnc} if exists $self->{rhnc};

    return;
}

=head1 DIAGNOSTICS



=head1 CONFIGURATION AND ENVIRONMENT

This program relies on the existance of a configuration file, either
F</etc/satellite_api.conf> or F<$HOME/.rhnrc>.

This file (in INI format) should contain three directives in the
C<[rhn]> section:

  [rhn]
  host=satellite.example.com
  user=rhn-admin
  password=s3cr3t

Both files can exist, information in  F<$HOME/.rhnrc> will take
precedence.

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

    perldoc RHNC


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

1;    # End of RHNC
