package RHNC;

use warnings;
use strict;
use vars qw( $AUTOLOAD %_properties );

use Params::Validate;
use Carp;

use Frontier::Client;
use RHNC::Session;
use RHNC::Org;
use RHNC::SystemGroup;

our $_xmlfalse = Frontier::RPC2::Boolean->new(0);
our $_xmltrue = Frontier::RPC2::Boolean->new(1);
our @EXPORTS  = qw( $VERSION );

#our $AUTOLOAD;

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

=head1 FUNCTIONS

=cut

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

    if ( ref $object !~ m{ \A RHN:: }imxs ) {
        return undef;
    }

    $object->{rhnc} = $self;

    $self->{_managed}{ $object->name() } = \$object;

    return $self;
}

=head2 unmanage( $obj )

Remove a specified object from list of managed object. Remove cross
references.

=cut
sub unmanage {
    my ( $self, $object ) = @_;

    if ( ref $object !~ m{ \A RHN:: }imxs ) {
        return undef;
    }

    delete $self->{_managed}{ $object->name() };
    $object->{rhnc} = undef;

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

use constant {
    DEFAULT   => 0,
    VALIDATE  => 1,
    TRANSFORM => 2,
};
my %_properties = ( rhnc => [ undef, undef, undef ], );

sub AUTOLOAD {
    my ( $self, $value ) = @_;
    my $attr = $AUTOLOAD;
    $attr =~ s{ \A .*:: }{}imxs;

    return undef
      if $attr =~ m{ \A [A-Z]+ }imxs;    # skip DESTROY and all-cap methods

    if ( ! defined $_properties{$attr} ) {
        croak "invalid accessor $attr()";
    }

    if ( defined $value ) {
        if ( defined $_properties{$attr}[TRANSFORM] ) {
            $value = $_properties{$attr}[TRANSFORM]($value);
        }

        if ( defined $_properties{$attr}[VALIDATE] ) {
            if ( $_properties{$attr}[VALIDATE]($value) ) {
                $self->{$attr} = $value;
            }
            else {
                croak "'$value' cannot be validated for attribute '$attr'";
            }
        }
        else {
            $self->{$attr} = $value;
        }
    }

    if ( !defined $self->{$attr} && defined $_properties{$attr}[DEFAULT] ) {
        $self->{$attr} = $_properties{$attr}[DEFAULT];
    }

    $self->{$attr};

}

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 CONFIGURATION

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

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

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


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC
