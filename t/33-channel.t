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

BEGIN { $tests++; }
ok( $channel->latest_packages() > 0,
    'Latest packages has more than one packages' );

BEGIN { $tests++; }
ok( keys( %{ $channel->list_errata()} )  > 0,
    'More than one errata for ' . $channel->label() );

BEGIN { $tests++; }
my $arches = $channel->list_arches();
ok( keys(%$arches) > 0, 'More than one arch in list : ' . join( ', ', keys %$arches ) );

BEGIN { $tests++; }
my $syslist = $channel->list_systems();
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
