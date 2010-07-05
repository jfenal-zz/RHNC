#!/usr/bin/perl
use Test::More;
use strict;
use warnings;
use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::Channel $RHNC::Channel::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my @channels = @{ RHNC::Channel::list($rhnc) };
BEGIN { $tests++; }
ok( scalar @channels >= 0, 'got a list of ' . scalar(@channels) . ' channels' );

my $tchan      = $channels[0];
my $tchan_name = $tchan->name;
BEGIN { $tests++; }
my $channel = $tchan->get();
is( ref($channel), 'RHNC::Channel',
    "first member of list is RHNC::Channel class" );

BEGIN { $tests++; }
ok( $channel->arch() =~ /IA-32|x86_64|i386|amd64|sparc/i, 'arch is fine' );

BEGIN { $tests+=4; }
my $plist;
ok(@{$plist = $channel->latest_packages()} > 0, 'Latest packages has more than one packages' );
ok(defined($plist->[0]->{rhnc}), "First package has its RHNC ref");
ok(ref $plist->[0]->{rhnc} eq 'RHNC::Session', "and its a RHNC::Session ref");
ok(@{$plist = $channel->latest_packages(1)} > 0, 'Latest packages (forced update) has more than one packages' );

BEGIN { $tests+=4; }
ok(@{ $plist = $channel->list_packages()} > 0, 'Latest packages has more than one packages' );
ok(defined $plist->[0]->{rhnc}, "First package has its RHNC ref");
ok(ref $plist->[0]->{rhnc} eq 'RHNC::Session', "and its a RHNC::Session ref");
ok(@{ $plist = $channel->list_packages(1)} > 0, 'Latest packages (forced update) has more than one packages' );


BEGIN { $tests++; }
ok( keys( %{ $channel->list_errata()} )  > 0,
    'More than one errata for ' . $channel->label() );

BEGIN { $tests++; }
my $errata = $channel->list_errata();
ok( keys(%$errata) > 0, 'More than one erratum in list : ' . join( ', ', keys %$errata ) );

BEGIN { $tests++; }
$errata = RHNC::Channel->list_errata( $rhnc, $channel->label );
ok( keys(%$errata) > 0, 'More than one erratum in list : ' . join( ', ', keys %$errata ) );

BEGIN { $tests++; }
$errata = RHNC::Channel::list_errata( $rhnc, $channel->id );
ok( keys(%$errata) > 0, 'More than one erratum in list : ' . join( ', ', keys %$errata ) );

BEGIN { $tests+=6; }
undef $errata;
eval { $errata = RHNC::Channel::list_errata( ); };      # won't work
ok( $@, "Error if no rhnc given 1" );
ok( keys(%$errata) == 0, 'no erratum if no $rhnc: ' . join( ', ', keys %$errata ) );
eval { $errata = RHNC::Channel->list_errata( ); };      # won't work
ok( $@, "Error if no rhnc given 2" );
ok( keys(%$errata) == 0, 'no erratum if no $rhnc: ' . join( ', ', keys %$errata ) );
my $c = $channel->get( $channel->id );
undef $c->{rhnc};
eval { $errata = $c->list_errata( ); };      # won't work
ok( $@, "Error if no rhnc given 3" );
ok( keys(%$errata) == 0, 'no erratum if no $rhnc: ' . join( ', ', keys %$errata ) );


BEGIN { $tests++; }
my $arches = $channel->list_arches();
ok( keys(%$arches) > 0, 'More than one arch in list : ' . join( ', ', keys %$arches ) );

BEGIN { $tests++; }
$arches = RHNC::Channel->list_arches( $rhnc );
ok( keys(%$arches) > 0, 'More than one arch in list : ' . join( ', ', keys %$arches ) );

BEGIN { $tests++; }
$arches = RHNC::Channel::list_arches( $rhnc );
ok( keys(%$arches) > 0, 'More than one arch in list : ' . join( ', ', keys %$arches ) );

BEGIN { $tests+=6; }
undef $arches;
eval { $arches = RHNC::Channel::list_arches( ); };      # won't work
ok( $@, "Error if no rhnc given 1" );
ok( keys(%$arches) == 0, 'no arch if no $rhnc: ' . join( ', ', keys %$arches ) );
eval { $arches = RHNC::Channel->list_arches( ); };      # won't work
ok( $@, "Error if no rhnc given 2" );
ok( keys(%$arches) == 0, 'no arch if no $rhnc: ' . join( ', ', keys %$arches ) );
$c = $channel->get( $channel->id );
undef $c->{rhnc};
eval { $arches = $c->list_arches( ); };      # won't work
ok( $@, "Error if no rhnc given 3" );
ok( keys(%$arches) == 0, 'no arch if no $rhnc: ' . join( ', ', keys %$arches ) );

BEGIN { $tests+=3 ; }
my $syslist;
$syslist = $channel->list_systems();
ok(keys %{ $syslist } >= 0, '0 or more systems subscribed' );
$syslist = RHNC::Channel->list_systems( $rhnc, $channel->name);
ok(keys %{ $syslist } >= 0, '0 or more systems subscribed' );
$syslist = RHNC::Channel::list_systems( $rhnc, $channel->id );
ok(keys %{ $syslist } >= 0, '0 or more systems subscribed' );
#isa_ok( $syslist->{(keys %$syslist)[0]}, 'RHNC::System', "first #system is a RHNC::System" ); #TODO

BEGIN { $tests++; }
my $new_chan = RHNC::Channel->create(
    rhnc         => $rhnc,
    label        => 'site-my-test-channel',
    name         => 'site-my-test-channel',
    summary      => 'site-my-test-channel',
    arch_name    => 'channel-ia32',
    parent_label => $tchan_name,
);
is( ref $new_chan, 'RHNC::Channel', 'New channel created' );

BEGIN { $tests++; }
ok( $new_chan->destroy, 'test-channel deleted' );
