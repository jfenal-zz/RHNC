package RHNC::Org;

use warnings;
use strict;
use Params::Validate;
use Carp;
use RHNC;

use base 'RHNC';

use vars qw( $AUTOLOAD %properties %valid_prefix );

=head1 NAME

RHNC::Org - Red Hat Network Client - Organisation handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::Org;

    # Create object, not yet on Satellite
    my $foo = RHNC::Org->new(
        name      => $orgName,
        login     => $adminLogin,
        password  => $adminPassword,
        prefix    => $prefix,
        firstname => $firstName,
        lastname  => $lastName,
        email     => $email
    );
    my $foo = RHNC::Org->new($org);  # From an already existing object

    # Create object + create it directly on Satellite.
    my $foo = RHNC::Org->create(
        rhnc      => $rhnc,          # RHNC object, referring to a RHNC::Session
        name      => $orgName,
        login     => $adminLogin,
        password  => $adminPassword,
        prefix    => $prefix,
        firstname => $firstName,
        lastname  => $lastName,
        email => $email usepam => $usePamAuth
    );
    my $foo = RHNC::Org->create($org);

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

  my $org => RHNC::Org->new(
      name       => $orgName,
      login      => $adminLogin,
      password   => $adminPassword,
      prefix     => prefix,
      firstname  => $firstName,
      lastname   => $lastName,
      email      => $email
      usepam     => $usePamAuth
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

#
# Accessors
#
use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %valid_prefix = map { $_ => 1 } qw( Dr. Hr. Miss Mr. Mrs. Sr. );
my %properties = (
    rhnc     => [ 0, undef, undef, undef ],
    name     => [ 1, undef, undef, undef ],
    login    => [ 0, undef, undef, undef ],
    password => [ 0, undef, undef, undef ],
    prefix =>
      [ 0, 'Mr.', sub { return defined $valid_prefix{ $_[0] } }, undef ],
    firstname              => [ 0, 'John',                 undef, undef ],
    lastname               => [ 0, 'Doe',                  undef, undef ],
    email                  => [ 0, 'john.doe@example.com', undef, undef ],
    usepam                 => [ 0, 0,                      undef, undef ],
    id                     => [ 0, 0,                      undef, undef ],
    active_users           => [ 0, 0,                      undef, undef ],
    systems                => [ 0, 0,                      undef, undef ],
    trusts                 => [ 0, 0,                      undef, undef ],
    system_groups          => [ 0, 0,                      undef, undef ],
    activation_keys        => [ 0, 0,                      undef, undef ],
    kickstart_profiles     => [ 0, 0,                      undef, undef ],
    configuration_channels => [ 0, 0,                      undef, undef ],
);

#FIXME

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    my %v = map { $_ => 0 } ( 'id', keys(%properties) );

    my %p = validate( @args, \%v );

    for my $i ( keys %properties ) {
        $self->{$i} = $p{$i};
    }

    bless $self, $class;

    return $self;
}

=head2 create


=cut

sub _missing_parameter {
    my $parm = shift;

    croak "Missing parameter $parm";

}

sub create {
    my ( $self, @args ) = @_;

    #    $self = ref($self) || $self;

    if ( !ref $self ) {
        $self = RHN::Org->new(@args);
    }

    foreach
      my $p (qw( name login password prefix firstname lastname email usepam))
    {
        if ( !defined $self->{$p} ) {
            _missing_parameter($p);
        }
    }
    my $res = $self->{rhnc}->call(
        'org.create',
        $self->{name},
        $self->{login},
        $self->{password},
        $self->{prefix},
        $self->{firstname},
        $self->{lastname},
        $self->{email},
        $self->{usepam} ? $RHNC::_xmltrue : $RHNC::_xmlfalse,
    );

    $self->{id} = $res->{id};

    return $self;
}

=head2 trust

  $org->trust( $orgid );
  $org->trust( $orgName );

=cut

sub trust {
    my ( $self, @args ) = @_;
    my $trustme = shift @args;

    if ( !defined $self->{rhnc} ) {
        croak "No client in this object " . ref($self) . ". Exiting";
    }
    $self->{rhnc}->call( 'org.trusts.addTrust', $self->{id}, $trustme );

    $self->{trusts}{$trustme}++;

    $self->{modified}++;

    return $self;
}

=head2 destroy

  $org->destroy();

=cut

sub destroy {
    my ( $self, @args ) = @_;

    if ( !defined $self->{rhnc} ) {
        croak "No client in this object " . ref($self) . ". Exiting";
    }
    $self->{rhnc}->call( 'org.delete', $self->{id} );

    $self = ();
    undef $self;
    return 1;
}

sub AUTOLOAD {
    my ( $self, $value ) = @_;
    my $attr = $AUTOLOAD;
    $attr =~ s{ \A .*:: }{}imxs;

    if ( !defined $properties{$attr} ) {
        return 0;
    }
    if ( $attr eq 'name' ) { return 0; }

    if ( defined $value ) {
        if ( defined $properties{$attr}[TRANSFORM] ) {
            $value = $properties{$attr}[TRANSFORM]($value);
        }

        if ( defined $properties{$attr}[VALIDATE] ) {
            if ( $properties{$attr}[VALIDATE]($value) ) {
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

    if ( !defined $self->{$attr} && defined $properties{$attr}[DEFAULT] ) {
        $self->{$attr} = $properties{$attr}[DEFAULT];
    }

    return $self->{$attr};
}

=head2 name 

Return name of organisation

=cut

sub name {
    my ( $self, $name ) = @_;
    if ( defined $name ) {

        if ( defined $self->{id} ) {
            $self->{name} = $name;
            my $res =
              $self->{rhnc}
              ->call( 'org.updateName', $self->{id}, $self->{name} );

            if ( !defined($name) || $res->{name} ne $name ) {
                croak
                  "Could not change Org name to '$name' for OrgId $self->{id}";
            }
        }
        else {
            croak "Cannot change Org Name to '$name' for unknown OrgId";
        }
    }

    return $self->{name};
}

=head2 id 

Return id of organisation

=cut

sub id {
    my $self = shift;

    return $self->{id} if defined $self->{id};
    return '';
}

=head2 list

Return list of Organisations

Can work in OO context if you have already an organisation at hand.

    @orgs = $org->list();

More likely in package context :

    @orgs = RHNC::Org->list( $RHNC );  # Need to specify a RHN client

=cut

sub list {
    my ( $self, $parm ) = @_;

    my $rhnc;
    if ( ref $self ) {    # OO context
        $rhnc = $self->{rhnc};
    }
    else {                # package context
        $rhnc = $parm;
    }

    my $res = $rhnc->call('org.listOrgs');

    my @orgs;
    foreach my $h ( @{$res} ) {

        my $o = __PACKAGE__->new(
            name => $h->{name},
            id   => $h->{id}
        );
        $rhnc->manage($o);

        push @orgs, $o;
    }

    return \@orgs;
}

=head2 info

Return information about organisation.

Can work in OO context if you have already an organisation at hand.

    @orgs = $org->info();

More likely in package context :

    $org = RHNC::Org->info( $RHNC, $name); # Need to specify a RHN client
    $org = RHNC::Org->info( $RHNC, $id);   # Need to specify a RHN client

=cut

sub info {
    my ( $self, $parm ) = @_;

    my $rhnc;
    if ( ref $self ) {    # OO context
        $rhnc = $self->{rhnc};
    }
    else {                # package context
        $rhnc = $parm;
    }

    my $res = $rhnc->call('org.getDetails');
    my $o   = __PACKAGE__->new( %{$res} );

    $rhnc->manage($o);

    return $o;
}

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn at rt.cpan.org>, or through
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
