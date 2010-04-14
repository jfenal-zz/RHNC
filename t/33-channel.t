#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::Channel $RHNC::Channel::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my @channels = RHNC::Channel::list($rhnc);
BEGIN { $tests++; }
ok( scalar @channels >= 0, 'got a list of '. scalar(@channels) .' channels' );



