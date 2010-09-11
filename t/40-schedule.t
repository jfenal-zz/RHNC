#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::SystemGroup $RHNC::SystemGroup::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

BEGIN { $tests++; }
my $l = RHNC::Schedule->actions( $rhnc );
isa_ok($l, 'ARRAY', 'list is a array ref');

