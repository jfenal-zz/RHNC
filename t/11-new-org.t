#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;

diag( "Testing RHNC::Org $RHNC::Org::VERSION, Perl $], $^X" );
my $tests;
plan tests => $tests;


my $rhnc = RHNC::Session->new();

my $org = RHNC::Org->new( rhnc=> $rhnc, 
    orgName => "Test Org",
    adminLogin => "test-admin",
    adminPassword => 'redhat',
    prefix => 'Mr.',
    firstName => 'shadowman',
    lastName => 'Test',
    email => 'test@example.com',
    usePamAuth => 0,
    );

BEGIN { $tests++ }
ok($org->create(), "org created");

BEGIN { $tests++ }
ok($org->delete(), "org deleted");

BEGIN { $tests++ }
is($org->orgName(), 'Test Org'); 

BEGIN { $tests++ }
is($org->adminLogin(), 'test-admin'); 



