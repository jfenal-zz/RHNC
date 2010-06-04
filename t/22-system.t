#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::SystemGroup $RHNC::SystemGroup::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $slist = RHNC::System->list( $rhnc );

my $system_id = (keys %$slist)[0];

BEGIN { $tests++ }
ok( RHNC::System::is_systemid($system_id), 'id ok ' . $system_id );

BEGIN { $tests++ }
my $sys = RHNC::System::get($rhnc, $system_id );
isa_ok($sys, 'RHNC::System', "object created is indeed a RHNC::System");

print Dumper \$sys;
