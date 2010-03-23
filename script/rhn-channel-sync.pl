#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Frontier::Client;
use Data::Dumper;
use Config::IniFiles;
use Getopt::Long;
use Pod::Usage;
use constant BATCHLOAD => 100;

our $VERSION = '1.0';

# $Id$
# $Revision$, $HeadURL$, $Date$

#
# _readconfig : lecture d'un fichier de configuration
#

sub _readconfig {
    my ( $self, $file ) = @_;

    if ( defined($file) && -r $file ) {
        my $cfg = Config::IniFiles->new( -file => $file );

        my @p = qw(host user password data);
        foreach my $p (@p) {
            my $v = $cfg->val( 'rhn', $p );
            if ( defined $v ) {
                $self->{$p} = $v;
            }
        }

    }
    return $self;
}

#
# _get_channel_list : récupération de la liste des canaux sur le satellite
#

sub _get_channel_list {
    my ( $client, $session ) = @_;
    my $channels = $client->call( 'channel.listSoftwareChannels', $session );

    return map { $_->{label} } @{$channels};
}

#
# Usage
#
sub usage {
    my $str = shift;

    if ( defined $str ) {
        print "$str\n";
    }
    pod2usage(1);
    return 0;    # not reached
}

# ---------------------------------------------------
# main
#

# Default configuration
my %config = (
    host     => 'localhost',
    user     => 'rhn-admin',
    password => 'none',
);

# fichiers de configuration
my @files = ( '/etc/satellite_api.conf', "$ENV{HOME}/.rhnrc" );
foreach my $f (@files) {
    _readconfig( \%config, $f );
}

my ( $src_channel, $dst_channel );
my $clone_errata = 0;
my $result       = GetOptions(
    'source|s=s' => \$src_channel,
    'dest|d=s'   => \$dst_channel,
    'errata|e'   => \$clone_errata,
);

#
# Initiation de la connexion
#
my $client = Frontier::Client->new( url => "http://$config{host}/rpc/api" );
my $session = $client->call( 'auth.login', $config{user}, $config{password} );
croak "Cannot initiate connection to $config{host}" if not defined $session;

#
# Validation des noms de canaux sources et destination
#
my %channel_exists = map { $_ => 1 } _get_channel_list( $client, $session );

if ( defined $src_channel || exists $channel_exists{$src_channel} ) {
    usage "Source channel <$src_channel> not defined";
}
if ( defined $dst_channel || exists $channel_exists{$dst_channel} ) {
    usage "Destination channel <$dst_channel> not defined";
}

if ($clone_errata) {
    print {*STDERR} "Will clone errata\n"
}

#
# clonage des errata
#
if ($clone_errata) {
    my @erratas = $client->call( 'channel.software.mergeErrata',
        $session, $src_channel, $dst_channel );
    for my $e (@erratas) {
        print {*STDERR} 'Merged ' . ${$e}->{id} . "\n";
    }
}

# ------------------------------------------------
# Clonage des packages
#

# creation d'un hash (index NVRA) recensant la liste des packages sources
my $src_packages =
  $client->call( 'channel.software.listAllPackages', $session, $src_channel );
my %src_pkgs = map {
    join( '-',
        $_->{name}, $_->{version}, $_->{release}, $_->{arch_label}, '.rpm' ) =>
      $_->{id}
} @{$src_packages};

# creation d'un hash (index NVRA) recensant la liste des packages existant en destination
my $existing_packages =
  $client->call( 'channel.software.listAllPackages', $session, $dst_channel );
my %existing_pkgs = map {
    join( '-',
        $_->{name}, $_->{version}, $_->{release}, $_->{arch_label}, '.rpm' ) =>
      $_->{id}
} @{$existing_packages};

# @needed_packages : tableau de la liste des packages
my @needed_packages = keys %src_pkgs;

# Nombre de packages total potentiellement à cloner
my $total     = scalar @needed_packages;
my $left_todo = $total;
my %todo;

while ( $total > 0 ) {

    #
    # On travaille par lots, l'API ne supportant pas de très grands
    # nombres de packages en paramètre
    #
    my @ptodo = splice @needed_packages, 0, BATCHLOAD;
    $total = scalar @needed_packages;

    %todo = map { $_ => $src_pkgs{$_} } @ptodo;

    #print Dumper \%todo;

    my $already_existing = 0;
    my $non_existing     = 0;
    foreach my $package ( keys %todo ) {
        my $name;
        if ( $package =~ m{ \A (.*?) - \d }msx ) {
            $name = $1;
        }
        next if $name eq '';
    }

    foreach my $package ( keys %todo ) {
        if ( defined $existing_pkgs{$package} ) {
            delete $todo{$package};
            $already_existing++;
            next;
        }

        if ( !defined $src_pkgs{$package} ) {
            delete $todo{$package};
            $non_existing++;
            next;
        }
        $left_todo = scalar @needed_packages;

    }

    $left_todo = scalar keys %todo;

    print
"Adding packages (Added: $left_todo, total left: $total, non existing in batch: $non_existing, already existing in batch: $already_existing).\n";

    my @ar = values %todo;

    #
    # envoi de la demande d'ajout si il y a des packages à ajouter
    #
    if ( scalar @ar > 0 ) {
        $client->call( 'channel.software.addPackages',
            $session, $dst_channel, \@ar );
    }
}

return 0;
__END__


=head1 NAME

sync-channel.pl - Synchronize two Red Hat Network Satellite channels

=head1 USAGE

 sync-channel.pl -s source-channel -d dest-channel [-e]

=head1 REQUIRED ARGUMENTS

=over

=item * -s source-channel

=item * --source source-channel

Specify the RHN software channel from which to get packages.

=item * -d destination-channel

=item * --dest destination-channel

Specify the RHN software channel where to add (missing) packages from the
source.

=back

=head1 OPTIONS

=item * -e

=item * --errata

Activate errata synchronisation between the two channels. Usually not
required, but here for completeness. See L<BUGS> for possible issue.

=over


=head1 DIAGNOSTICS

=head1 EXIT STATUS

Script will return 0 in case of success, non zero in case of failure
or error.



=head1 DESCRIPTION

sync-channel.pl will clone packages from one existing channel to a new one,
possibly a clone.

=head1 BUGS AND LIMITATIONS

The source and destination channel MUST exist, the script will B<not> create
the destination channel, as a safety mesure.

Errata synchronisation may end up in an Error 500 if all errata already
cloned.

=head1 EXAMPLES

  sync-channel.pl -s redhat-rhn-satellite-5.3-server-x86_64-5 -c clone-redhat-rhn-satellite-5.3-server-x86_64-5

=head1 CONFIGURATION

This program relies on the existance of a configuration file, either
F</etc/satellite_api.conf> or F<$HOME/.rhnrc>.

This file (in INI format) should contain three directives in the C<[rhn]>
section:

  [rhn]
  host=satellite.example.com
  user=rhn-admin
  password=s3cr3t

Both files can exist, information in  F<$HOME/.rhnrc> will take precedence.

=head1 DEPENDENCIES

Script depends on the following Perl modules, available on a stock Red
Hat Network Satellite installation :

  - Carp
  - Pod::Usage
  - Frontier::Client
  - Data::Dumper (FIXME: debug)
  - Getopt::Long
  - Config::IniFiles

=head1 INCOMPATIBILITIES

=head1 AUTHOR

Jérôme Fenal, C<jfenal@redhat.com>.

=head1 LICENSE AND COPYRIGHT

Copyright © 2010, Jérôme Fenal. All Rights Reserved

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

