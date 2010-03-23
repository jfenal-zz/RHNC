package RHNC::Session;

use warnings;
use strict;
use English;
use Frontier::Client;
use Params::Validate;
use Config::IniFiles;

use base qw( RHNC );

# $Id$

#$VERSION     = 0.01;
#@ISA         = qw(Exporter);
#@EXPORT      = ();
#@EXPORT_OK   = qw(Session Barename GetSID);
#%EXPORT_TAGS = ( DEFAULT => [qw(&Session &Barename &GetSID)] );

=head1 NAME

RHNC::Session - Initiate a new connection to RHNC Satellite

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use RHNC::Session;

  my $foo = RHNC::Session->new( "$ENV{HOME}/.rhnrc" );

=head1 DESCRIPTION

RHNC::Session handles all XMLRPC connection initiating.

=head1 SUBROUTINES/METHODS

=head2 _readconfig

Just read a config file

=cut

sub _readconfig {
    my ( $self, $file, $section ) = @_;

    # if given parameter defined, and exist as a file, use it.
    if ( defined $file && -f $file ) {

        # create new config object from file
        my $config = Config::IniFiles->new( -file => $file );

        my @p = qw(server user password data);

        # loop on all accepted parameters (@p)
        foreach my $p (@p) {

            # get given value in config for parameter
            my $v = $config->val( $section, $p );

            # if defined, use it
            if ( defined $v ) {
                $self->{$p} = $v;
            }
        }

        # define client version
        $self->{version} = $VERSION;

    }
    return $self;
}

=head2 new

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my @files = ( '/etc/satellite_api.conf', "$ENV{HOME}/.rhnrc" );
    my %p = validate( @args, { config => 0, section => 0 } );
    my $self = {};
    bless $self, $class;

    $self->{server}   = 'localserver';
    $self->{user}     = 'rhn-admin';
    $self->{password} = 'none';
    $self->{section}  = 'rhn';

    if ( ref $class ) {
        $self->{server}   = $class->{server};
        $self->{user}     = $class->{user};
        $self->{password} = $class->{password};
        $self->{section}  = $class->{section};
    }

    # load all config files in order
    foreach my $f ( @files, $p{config} ) {
        if ( defined $f && -f $f ) {

            #            print {*STDERR} "Trying $f\n";
            $self->_readconfig( $f, $self->{section} );
        }
    }

    $self->{client} =
      Frontier::Client->new( url => 'https://' . $self->{server} . '/rpc/api' );
    my $session =
      $self->{client}->call( 'auth.login', $self->{user}, $self->{password} );
    $self->{session} = $session;

    $self->{apiversion}    = $self->{client}->call('api.getVersion');
#    $self->{apiversion} += 0;
    $self->{systemversion} = $self->{client}->call('api.systemVersion');
#    $self->{systemversion} += 0;
    my $r = $self->call( 'user.getDetails', $self->{user} );
    $self->{org_id} = $r->{org_id};

    # forget password
    delete $self->{password};
    return $self;
}

=head2 call

Calls the requested method, returns whatever is returned by Frontier::Client::call
 
=cut

sub call {
    my ( $self, $call, @args ) = @_;

    my $result;

    # protect call with eval to catch possible exception
    my $rc = eval {
        $result = $self->{client}->call( $call, $self->{session}, @args );
    };

    # test eval (according PBP, testing $@ is not reliable)
    if ( !defined $rc ) {
        print STDERR "Error encountered calling $call : $EVAL_ERROR\n";
        $result = undef;
    }

    return $result;
}

=head2 org_id

Returns current org_id

=cut

sub org_id {
    my ( $self, @args ) = @_;

    return $self->{org_id};
}

=head2 server

Returns current org_id

=cut

sub server {
    my ( $self, @args ) = @_;

    return $self->{server};
}

=head2 apiversion

Returns API version number

=cut

sub apiversion {
    my ( $self, @args ) = @_;

    return $self->{apiversion};
}

=head2 systemversion

Returns Satellite version number

=cut

sub systemversion {
    my ( $self, @args ) = @_;

    return $self->{systemversion};
}

=head2 version

Returns client version number

=cut

sub version {
    my ( $self, @args ) = @_;

    return $self->{version};
}

=head1 DIAGNOSTICS

=head1 INCOMPATIBILITIES

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHNC-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHNC::Session


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




=head1 LICENSE AND COPYRIGHT

Copyright © 2010 Jérôme Fenal, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHNC::Session
