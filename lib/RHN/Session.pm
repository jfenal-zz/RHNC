package RHN::Session;

use warnings;
use strict;
use Frontier::Client;
use Params::Validate;
use Config::Tiny;

#$VERSION     = 0.01;
#@ISA         = qw(Exporter);
#@EXPORT      = ();
#@EXPORT_OK   = qw(Session Barename GetSID);
#%EXPORT_TAGS = ( DEFAULT => [qw(&Session &Barename &GetSID)] );

=head1 NAME

RHN::Session - Initiate a new connection to RHN Satellite

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

RHN::Session handles all XMLRPC connection initiating.

Perhaps a little code snippet.

    use RHN::Session;

    my $foo = RHN::Session->new( "$ENV{HOME}/.rhnrc" );
    ...

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my ( $class, @args ) = @_;
    my %p =
      validate( @args, { config => { default => "/etc/satellite_api.conf" } } );
    my $fconfig;
    my $self = {};
    bless $self, $class;

    open( $fconfig, '<', $p{config} )
      or die "Couldn't open file for reading: $!";

# /etc/satellite_api.conf should contain only a single line # seperated by spaces
    $_ = <$fconfig>;
    my ( $HOST, $USER, $PASS ) = (split);
    close($fconfig)
      or die "Can't close config file $p{config} ($!)";

    $self->{client}   = Frontier::Client->new( url => "http://$HOST/rpc/api" );
    $self->{host}     = $HOST;
    $self->{user}     = $USER;
    $self->{password} = $PASS;
    $self->{version}  = $VERSION;

    my $session = $self->{client}->call( 'auth.login', $USER, $PASS );

    return $self;
}

=head2 call

Calls the requested method, returns whatever is returned by Frontier::Client::call
 
=cut

sub call {
    my ( $self, @args ) = @_;

    my $result = $self->{client}->call( $self->{session}, @args );

    return $result;
}

=head2 version

Returns version number

=cut

sub version {
    my ( $self, @args ) = @_;

    return $self->{version};
}


=head1 AUTHOR

Jérôme Fenal, C<< <jfenal at redhat.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rhn-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RHN-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RHN::Session


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RHN-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RHN-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RHN-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/RHN-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jérôme Fenal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of RHN::Session
