package RHNC::Org;

use warnings;
use strict;
use Params::Validate;
use Carp;
use RHNC;

our @ISA = qw( RHNC );

use vars qw( $AUTOLOAD %_properties );

=head1 NAME

RHNC::Org - The great new RHNC::Org!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use RHNC::Org;

    my $foo = RHNC::Org->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

  my $org => RHNC::Org->new(
      orgName       => $orgName,
      adminLogin    => $adminLogin,
      adminPassword => $adminPassword,
      prefix        => prefix,
      firstName     => $firstName,
      lastName      => $lastName,
      email         => $email
      usePamAuth    => $usePamAuth
  );

    - string orgName - Organization name. Must meet same criteria as in the web UI.
    - string adminLogin - New administrator login name.
    - string adminPassword - New administrator password.
    - string prefix - New administrator's prefix. Must match one of the
      values available in the web UI. (i.e. Dr., Mr., Mrs., Sr., etc.)
    - string firstName - New administrator's first name.
    - string lastName - New administrator's first name.
    - string email - New administrator's e-mail.
    - boolean usePamAuth - true if PAM authentication should be used for the new administrator account.

=cut

my @priv = qw( rhnc orgName adminLogin adminPassword prefix firstName lastName
  email usePamAuth );

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    my %v = map { $_ => 1 } @priv;

    my %p = validate( @args, \%v );

    for my $i (@priv) {
        $self->{"_$i"} = $p{$i};
    }

    bless $self, $class;

    return $self;
}

=head2 create


=cut

sub create {
    my ( $self, @args ) = @_;

    #    $self = ref($self) || $self;

    if ( !ref $self ) {
        $self = RHN::Org->new(@args);
    }
    my $res = $self->{_rhnc}->call(
        'org.create',
        $self->{_orgName},
        $self->{_adminLogin},
        $self->{_adminPassword},
        $self->{_prefix},
        $self->{_firstName},
        $self->{_lastName},
        $self->{_email},
        $self->{_usePamAuth} ? $RHNC::_xmltrue : $RHNC::_xmlfalse,
    );

    $self->{_id} = $res->{id};

    return $self;
}

=head2 trust

  $org->trust( $orgid );
  $org->trust( $orgName );

=cut

sub trust {
    my ( $self, @args ) = @_;
    my $trustme = shift @args;

    if ( !defined $self->{_rhnc} ) {
        croak "No client in this object " . ref($self) . ". Exiting";
    }
    $self->{_rhnc}->call( 'org.trusts.addTrust', $self->{_id}, $trustme );

    $self->{trusts}{$trustme}++;

    $self->{_modified}++;

    return $self;
}

=head2 delete

  $org->delete();

=cut

sub delete {
    my ( $self, @args ) = @_;

    if ( !defined $self->{_rhnc} ) {
        croak "No client in this object " . ref($self) . ". Exiting";
    }
    $self->{_rhnc}->call( 'org.delete', $self->{_id} );

    $self = undef;
    return 1;
}

#
# Accessors
#
use constant {
    DEFAULT   => 0,
    VALIDATE  => 1,
    TRANSFORM => 2,
};

my %_valid_prefix = map { $_ => 1 } qw( Dr. Hr. Miss Mr. Mrs. Sr. );
my %_properties = (
    _rhnc          => [ undef, undef, undef ],
    _orgName       => [ undef, undef, undef ],
    _adminLogin    => [ undef, undef, undef ],
    _adminPassword => [ undef, undef, undef ],
    _prefix => [ 'Mr.', sub { return defined $_valid_prefix{ $_[0] } }, undef ],
    _firstName  => [ 'John', undef, undef ],
    _lastName   => [ 'Doe', undef, undef ],
    _email      => [ 'john.doe@example.com', undef, undef ],
    _usePamAuth => [ 0, undef, undef ],
);

sub AUTOLOAD {
    my ( $self, $value ) = @_;
    my $attr = $AUTOLOAD;
    $attr =~ s{ \A .*:: }{}imxs;
    $attr = "_$attr";

    if ( !defined $_properties{$attr} ) {
        return undef;
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

    return $self->{$attr};
}

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Org


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

1;    # End of RHNC::Org
