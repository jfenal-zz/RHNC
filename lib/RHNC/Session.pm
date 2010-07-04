package RHNC::Session;

use warnings;
use strict;
use Carp;
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
my $ONE_HOUR = 3600;

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

=head2 is_session

Return a true value if parameter is a session, false otherwise.

  $is_session = RHNC::Session::is_session( $p );

=cut

sub is_session {
    my ($p) = @_;

    if (ref $p eq 'RHNC::Session') {
        return 1;
    }
    return 0;

}


=head2 new

 # Clone session
 $rhnsession = $oldrhnsession->new();

 # Create session, read from configuration file, use "rhn" section.
 $rhnsession = RHNC::Session->new();

 # Same, but use "rhn2" section in the $filename file.
 $rhnsession = RHNC::Session->new( config => $filename, section => 'rhnc2');

 # Create new session, retrieve existing session information file.
 $rhnsession = RHNC::Session->new( username => 'user', server => 'server');

 # Create new session, using full information given
 $rhnsession = RHNC::Session->new( server => 'server', username => 'user', password => 's3kr3t' );

=cut

my @files = ( '/etc/satellite_api.conf', "$ENV{HOME}/.rhnrc" );

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my %p = validate(
        @args,
        {
            config   => 0,
            section  => 0,
            username => 0,
            password => 0,
            server   => 0
        }
    );
    my $self = {};
    bless $self, $class;

    # Set defaults
    $self->{server}   = 'localserver';
    $self->{username} = 'rhn-admin';
    $self->{password} = 'none';
    $self->{section}  = 'rhn';
    if ( defined $p{section} ) {
        $self->{section} = $p{section};
    }

    # Clone case
    if ( ref $class ) {
        $self->{server}   = $class->{server};
        $self->{username} = $class->{username};
        $self->{password} = $class->{password};
        $self->{section}  = $class->{section};
    }

    # Retrieve session from disk if available
    if ( $self->session_to_disk() ) {
        croak "Session loaded, but not defined, should not happen"
          if not defined $self->{session};
        return $self;
    }

    # No session on disk, try to work from config file or parameters.

    # 1: from parameters
    if ( defined $p{server} && defined $p{username} && defined $p{password} ) {
        $self->{server}   = $p{server};
        $self->{username} = $p{username};
        $self->{password} = $p{password};
    }
    else {

        # load all config files in order, reading from $p{config} if exists
        foreach my $f ( @files, $p{config} ) {
            if ( defined $f && -f $f ) {
                $self->_readconfig( $f, $self->{section} );
            }
        }
    }

    $self->{client} =
      Frontier::Client->new( url => 'https://' . $self->{server} . '/rpc/api' );
    my $session =
      $self->{client}
      ->call( 'auth.login', $self->{username}, $self->{password} );
    $self->{session} = $session;

    # Retrieve api & system versions
    $self->{apiversion}    = $self->{client}->call('api.getVersion');
    $self->{systemversion} = $self->{client}->call('api.systemVersion');

    # Retrieve user details, to get org_id.
    my $r = $self->call( 'user.getDetails', $self->{username} );
    $self->{org_id} = $r->{org_id};

    # forget password
    delete $self->{password};
    return $self;
}

=head2 session_to_disk

    # server & username already in object. Retrieve $sessions
    $session = $rhnc->session;

    # retrieve from file : specify which server/username to retrieve
    # key for
    $session = $rhnc->session( $server, $username );


Retrieve current session from F<$HOME/.rhn.server.username> or create a new
one if we can.
Do nothing if nothing could be done (no session file nor session
information in Session object).

=cut

sub session_to_disk {
    my ( $self, @args ) = @_;

    my ( $username, $server );

    # object context, username & server keys defined.
    if (   ref $self eq __PACKAGE__
        && defined $self->server
        && defined $self->username )
    {
        $server   = $self->server;
        $username = $self->username;
    }
    else {
        ( $username, $server ) = @args;
        if ( !defined $username || !defined $server ) {
            croak 'Can\'t do anything without username & server.  Exiting.';
        }
    }

    my $session_file_name = "$ENV{HOME}/.rhn.$server.$username";

    #
    # if we have a file, assume it's still ok, get its content, and
    # return the session key.
    #
    if ( -w $session_file_name ) {
        my $mtime = ( stat($session_file_name) )[9];

        if ( abs( time - $mtime ) < $ONE_HOUR ) {
            open my $f, '<', $session_file_name
              or croak "Cannot open session file $session_file_name for read";
            my $session = <$f>;
            close $f
              or croak "Cannot close session file $session_file_name for read";

            $self->{session} = $session;
            return $session;
        }
        else {

            # file too old, try other options
            unlink $session_file_name;
        }
    }

    #
    # no file, check if we have a session key to create one
    #
    if ( defined $self->session ) {
        open my $f, '>', $session_file_name
          or croak "Cannot open session file $session_file_name for write";
        print {$f} $self->session;
        close $f
          or croak "Cannot close session file $session_file_name for write";

        return $self->session;
    }
    else {
        return
          ; # do nothing, return nothing, as no current session, nor file to read from
    }
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

=head2 session

Returns or updates current session

=cut

sub session {
    my ( $self, @args ) = @_;

    if ( @args == 1 ) {
        $self->{org_id} = $args[0];
    }

    return $self->{org_id};
}

=head2 org_id

Returns current org_id

=cut

sub org_id {
    my ( $self, @args ) = @_;

    return $self->{org_id};
}

=head2 server

Returns current server name

=cut

sub server {
    my ( $self, @args ) = @_;

    return $self->{server};
}

=head2 username

Returns current user name

=cut

sub username {
    my ( $self, @args ) = @_;

    return $self->{username};
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
