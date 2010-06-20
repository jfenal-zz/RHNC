package RHNC::Org;

use warnings;
use strict;
use Params::Validate;
use Carp;

use base 'RHNC';

use vars qw( %properties %valid_prefix );

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

    - string orgName - Organization name. Must meet same criteria as
      in the web UI.
    - string adminLogin - New administrator login name.
    - string adminPassword - New administrator password.
    - string prefix - New administrator's prefix. Must match one of the
      values available in the web UI. (i.e. Dr., Mr., Mrs., Sr., etc.)
    - string firstName - New administrator's first name.
    - string lastName - New administrator's first name.
    - string email - New administrator's e-mail.
    - boolean usePamAuth - true if PAM authentication should be used
      for the new administrator account.

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
    id                     => [ 0, 0,                  undef, undef ],
    rhnc                   => [ 0, undef,              undef, undef ],
    name                   => [ 1, undef,              undef, undef ],
    login                  => [ 1, undef,              undef, undef ],
    password               => [ 1, undef,              undef, undef ],
    firstname              => [ 0, 'John',             undef, undef ],
    lastname               => [ 0, 'Doe',              undef, undef ],
    usepam                 => [ 0, 0,                  undef, undef ],
    active_users           => [ 0, 0,                  undef, undef ],
    systems                => [ 0, 0,                  undef, undef ],
    trusts                 => [ 0, 0,                  undef, undef ],
    system_groups          => [ 0, 0,                  undef, undef ],
    activation_keys        => [ 0, 0,                  undef, undef ],
    kickstart_profiles     => [ 0, 0,                  undef, undef ],
    configuration_channels => [ 0, 0,                  undef, undef ],
    email                  => [ 0, 'jdoe@example.com', undef, undef ],
    prefix =>
      [ 0, 'Mr.', sub { return defined $valid_prefix{ $_[0] } }, undef ],
);

#FIXME

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};
    bless $self, $class;

    my %v = map { $_ => 0 } ( keys(%properties) );

    my %p = validate( @args, \%v );

    for my $i ( keys %properties ) {
        $self->{$i} = $p{$i};
    }

    if ( defined $self->{rhnc} ) {
        $self->{rhnc}->manage($self);
    }

    return $self;
}

=head2 create

Create an organisation

Required parameters : name, login, password, prefix, firstname,
lastname, email, usepam.

=cut

sub _missing_parameter {
    my ( $self, $parm ) = @_;

    if ( !defined $properties{$parm}[DEFAULT] ) {
        croak "Missing parameter $parm";
    }

    $self->{$parm} = $properties{$parm}[DEFAULT];
    return $self->{$parm};
}

sub create {
    my ( $self, @args ) = @_;

    if ( !ref $self ) {
        $self = __PACKAGE__->new(@args);
    }

    foreach
      my $p (qw( name login password prefix firstname lastname email usepam))
    {
        if ( !defined $self->{$p} ) {
            $self->_missing_parameter($p);
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
    if ( defined $res ) {
        $self->{id} = $res->{id};

        return $self;
    }
    return;
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

=head2 save

  $org-save();

Save modifications to the object. Name only. See also C<name()>.

=cut

sub save {
    my ($self) = @_;

    # We can only save name for an organisation...
    $self->name( $self->{name} );

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

#
#sub AUTOLOAD {
#    my ( $self, $value ) = @_;
#    my $attr = $AUTOLOAD;
#    $attr =~ s{ \A .*:: }{}imxs;
#
#    if ( !defined $properties{$attr} ) {
#        return 0;
#    }
#
#    if ( defined $value ) {
#        if ( defined $properties{$attr}[TRANSFORM] ) {
#            $value = $properties{$attr}[TRANSFORM]($value);
#        }
#
#        if ( defined $properties{$attr}[VALIDATE] ) {
#            if ( $properties{$attr}[VALIDATE]($value) ) {
#                $self->{$attr} = $value;
#            }
#            else {
#                croak "'$value' cannot be validated for attribute '$attr'";
#            }
#        }
#        else {
#            $self->{$attr} = $value;
#        }
#    }
#
#    if ( !defined $self->{$attr} && defined $properties{$attr}[DEFAULT] ) {
#        $self->{$attr} = $properties{$attr}[DEFAULT];
#    }
#
#    return $self->{$attr};
#}

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

=head2 kickstart_profiles 

Return number of kickstart_profiles in an org.

=cut

sub kickstart_profiles {
    my $self = shift;

    return $self->{kickstart_profiles};
}

=head2 systems

Return number of systems in an org.

=cut

sub systems {
    my $self = shift;

    return $self->{systems};
}

=head2 active_users

Return number of active_users in an org.

=cut

sub active_users {
    my $self = shift;

    return $self->{active_users};
}

=head2 activation_keys

Return number of activation_keys in an org.

=cut

sub activation_keys {
    my $self = shift;

    return $self->{activation_keys};
}

=head2 system_groups

Return number of system_groups in an org.

=cut

sub system_groups {
    my $self = shift;

    return $self->{system_groups};
}

=head2 configuration_channels

Return number of configuration_channels in an org.

=cut

sub configuration_channels {
    my $self = shift;

    return $self->{configuration_channels};
}

=head2 prefix 

Return prefix for org user

=cut

sub prefix {
    my $self = shift;

    return $self->{prefix};
}

=head2 firstname 

Return firstname for org user

=cut

sub firstname {
    my $self = shift;

    return $self->{firstname};
}

=head2 lastname 

Return lastname for org user

=cut

sub lastname {
    my $self = shift;

    return $self->{lastname};
}

=head2 email 

Return email for org user

=cut

sub email {
    my $self = shift;

    return $self->{email};
}

=head2 usepam 

Return usepam for org user

=cut

sub usepam {
    my $self = shift;

    return $self->{usepam};
}

=head2 login 

Return login for organisation

=cut

sub login {
    my $self = shift;

    return $self->{login};
}

=head2 id 

Return id of organisation

=cut

sub id {
    my $self = shift;

    return $self->{id};
}

=head2 list

Return list of Organisations

Can work in OO context if you have already an organisation at hand.

    @orgs = $org->list();

More likely in package context :

    @orgs = RHNC::Org->list( $RHNC );  # Need to specify a RHN client

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
    elsif ( $self eq __PACKAGE__ ) {

        # Called as RHNC::Kickstart->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given";
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

=head2 get

Return information about organisation.

Can work in OO context if you have already an organisation at hand.

    @orgs = $org->get();

More likely in package context :

    $org = RHNC::Org->get( $RHNC, $name); # Need to specify a RHN client
    $org = RHNC::Org->get( $RHNC, $id);   # Need to specify a RHN client

=cut

sub get {
    my ( $self, @p ) = @_;

    my $rhnc;
    if ( ref $self ) {    # OO context
        $rhnc = $self->{rhnc};
    }
    else {                # package context
        $rhnc = shift @p;
    }
    my $k = shift @p;

    my $res = $rhnc->call( 'org.getDetails', $k );
    my $o = __PACKAGE__->new( %{$res} );

    $rhnc->manage($o);

    return $o;
}

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

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

Copyright © 2009, 2010 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::Org
