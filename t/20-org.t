#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::Org $RHNC::Org::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $org = RHNC::Org->new(
    rhnc      => $rhnc,
    name      => "Test Org",
    login     => "test-admin",
    password  => 'redhat',
    prefix    => 'Mr.',
    firstname => 'shadowman',
    lastname  => 'Test',
    email     => 'test@example.com',
    usepam    => 0,
);

BEGIN { $tests++ }
ok( $org->create(), 'org created' );

BEGIN { $tests += 7; }
is( $org->name(),     'Test Org',   'name accessor' );
is( $org->login(),    'test-admin', 'login accessor' );

#is($org->adminPassword(), '', 'adminPassword accessor (empty string)');
#ok( ! defined $org->adminPassword(), 'adminPassword accesssor (undef)');
is( $org->prefix(),    'Mr.',              'prefix accessor' );
is( $org->firstname(), 'shadowman',        'firstname accessor' );
is( $org->lastname(),  'Test',             'lastname accessor' );
is( $org->email(),     'test@example.com', 'email accessor' );
is( $org->usepam(),    0,                  'usepam accessor' );

BEGIN { $tests++ }
is( $org->name("New name"), "New name", "Change name" );

BEGIN { $tests++ }
my $l = RHNC::Org->list($rhnc);
isa_ok( $l, 'ARRAY', "List is indeed a ARRAYref" );

#print STDERR $_->name() . "\n" for ( @{$l} );

BEGIN { $tests++ }
ok( $org->destroy(), 'org deleted' );

BEGIN { $tests++ }
ok($rhnc->logout,'logout');

