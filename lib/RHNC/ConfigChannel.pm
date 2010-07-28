package RHNC::ConfigChannel;

use warnings;
use strict;
use Carp;
use Params::Validate;

use base qw( RHNC );

=head1 NAME

RHNC::ConfigChannel - Red Hat Network Client - Configuration Channels handling

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use RHNC::ConfigChannel;

    my $foo = RHNC::ConfigChannel->new();
    ...

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 _uniqueid

Returns a C<RHNC::ConfigChannel> object instance's unique id (id).

  $id = $object->_uniqueid;

=cut

sub _uniqueid {
    my ($self) = @_;
    return $self->{label};
}

use constant {
    MANDATORY => 0,
    DEFAULT   => 1,
    VALIDATE  => 2,
    TRANSFORM => 3,
};

my %properties = (
    rhnc        => [ 0, undef, 0, undef ],
    label       => [ 1, undef, 0, undef ],
    name        => [ 0, undef, 0, undef ],
    description => [ 0, undef, 0, undef ],
    configChannelType => [ 0, undef, 0, undef ],
    orgId => [ 0, undef, 0, undef ],
    id => [ 0, undef, 0, undef ],
);

sub _setdefaults {
    my ( $self, @args ) = @_;

    foreach ( keys %properties ) {
        if ( ref $properties{$_}[DEFAULT] eq 'CODE' ) {
            $self->{$_} = $properties{$_}[DEFAULT]($self);
        }
        else {
            $self->{$_} = $properties{$_}[DEFAULT];
        }
    }
    return $self;
}

sub _validate_properties {
    my ( $self, @args ) = @_;

    foreach ( keys %properties ) {
        if ( $properties{$_}[MANDATORY] && !defined( $self->{$_} ) ) {
            croak "Mandatory parameter $_ not present in object " . $self->name;
        }

        if ( ref $properties{$_}[VALIDATE] eq 'CODE' ) {
            if ( $properties{$_}[VALIDATE]( $self->{$_} ) ) {
                croak "Property $_ does not pass validation for object"
                  . $self->name;
            }
        }
    }
    return $self;
}

=head2 new

Create a new configuration channel object.

  @options = (
      label       => 'label',
      name        => 'name',
      description => 'description',
  
  );
  my $cc = RHNC::ConfigChannel->new( $rhnc, @options );
  my $cc = RHNC::ConfigChannel::new( $rhnc, @options );

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    if ( $class ne __PACKAGE__ ) {
        unshift @args, $class;
    }

    my $self = {};
    bless $self, __PACKAGE__;

    my %v = map { $_ => 0 } ( keys %properties );

    # validate args given
    my %p = validate( @args, \%v );

    # populate object from defaults
    $self->_setdefaults();

    # populate object from @args
    for my $i ( keys %properties ) {
        if ( defined $p{$i} ) {
            $self->{$i} = $p{$i};
        }
    }
    if ( ! defined $self->{name} ) { $self->{name} = $self->{label}; }
    if ( ! defined $self->{description} ) { $self->{description} = $self->{label}; }

    # validate object content
    $self->_validate_properties;
    

    return $self;
}

=head2 create

Create a new configuration channel.

  $cc = RHNC::ConfigChannel->create(
      rhnc        => $rhnc,           # mandatory
      label       => $label,          # mandatory
      name        => $name,           # optional, defaults to label
      description => $description,    # optional, defaults to label
  );
=cut

sub create {
    my ($class, @args) = @_;

    $class = ref($class) || $class;
    if ( $class ne __PACKAGE__ ) {
        unshift @args, $class;
        $class = __PACKAGE__;
    }

    my $self = __PACKAGE__->new(@args);

    croak 'No RHNC client to persist to, exiting'
      if !defined $self->{rhnc};

        $self->{rhnc}->manage($self);

    my $res = $self->{rhnc}->call(
        'configchannel.create', $self->{label},
        $self->{name},   $self->{description},
    );
    croak 'Create did not work' if !defined $res;
    $self->{id} = $res->{id};
    $self->{org_id} = $res->{orgId};
    $self->{configChannelType} = $res->{configChannelType};

    return $self;
}

=head2 label

Return config channel label

=cut

sub label {
    my ($self)= @_;

    return $self->{label};
}

=head2 get 

TODO 
by id or label

    Calls :
    - getDetails
    - lookupChannelInfo
=cut

=head2 list_files

TODO 
verbose to get file info ?

=cut 

=head2 list

List all the global config channels accessible to the logged-in user. 

=cut

sub list {
    my ( $self, @p ) = @_;
    my $rhnc;

    if ( ref $self eq __PACKAGE__ && defined $self->{rhnc} ) {

        # OO context, eg $ak-list
        $rhnc = $self->{rhnc};
    }
    elsif ( ref $self eq 'RHNC::Session' ) {

        # Called as RHNC::ActivationKey::List($rhnc)
        $rhnc = $self;
    }
    elsif ( $self eq __PACKAGE__ && ref( $p[0] ) eq 'RHNC::Session' ) {

        # Called as RHNC::ActivationKey->List($rhnc)
        $rhnc = shift @p;
    }
    else {
        croak "No RHNC client given here";
    }
    my $l = [];
    my $res = $rhnc->call('configchannel.listGlobals');
    foreach my $o (@$res) {
        push @$l, __PACKAGE__->new(rhnc => $rhnc, %$o);
    }

    return $l;

}

=head2 name

Get or set config channel name.

  $name = $cc->name;
  $oldname = $cc->name('newname');

=cut 

sub name {
    my ( $self, $name ) = @_;
    my $prev = $self->{name};

    if ( defined $name && $prev ne $name ) {
        $self->{name} = $name;
        my $res =
          $self->{rhnc}
          ->call( 'configchannel.update', $self->{label}, $self->{name},
            $self->{description}, );
    }

    return $prev;
}

=head2 description

Get or set config channel description.

  $description = $cc->description;
  $olddescription = $cc->description('newdescription');

=cut 

sub description {
    my ( $self, $description ) = @_;
    my $prev = $self->{description};

    if ( defined $description && $prev ne $description ) {
        $self->{description} = $description;
        my $res =
          $self->{rhnc}
          ->call( 'configchannel.update', $self->{label}, $self->{name},
            $self->{description}, );
    }

    return $prev;
}

=head2 destroy

Delete a configuration channel

FIXME : no API for this...

=cut

sub destroy {
    croak "This method cannot be implemented, missing API call"; 
}


=head2 schedule_file_compare

API : configchannel.scheduleFileComparisons

=cut

=head2 create or update path

API : configchannel.createOrUpdatePath

    * string sessionKey
    * string configChannelLabel
    * string path
    * boolean isDir - True if the path is a directory, False if it is a file.
    * struct - path info
          o string "contents" - Contents of the file (text or base64 encoded if binary). (ignored for directories)
          o string "owner" - Owner of the file/directory.
          o string "group" - Group name of the file/directory.
          o string "permissions" - Octal file/directory permissions (eg: 644)
          o string "macro-start-delimiter" - Config file macro start delimiter. Use null or empty string to accept the default. (ignored if working with a directory)
          o string "macro-end-delimiter" - Config file macro end delimiter. Use null or empty string to accept the default. (ignored if working with a directory)


Create a new ConfigChannel::Path namespace ??
Or ConfigChannelPath ??

=cut

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

    perldoc RHNC::ConfigChannel


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

Copyright 2009, 2010 Jerome Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::ConfigChannel
