#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

use lib qw( . lib lib/RHNC );
use RHNC;
use Carp;

diag("Testing RHNC::ActivationKey $RHNC::ActivationKey::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $ak;

# 1. create test AK
$ak = RHNC::ActivationKey::create(
    rhnc        => $rhnc,
    description => "Test activation key",
);

# 2. get entitlements
my @entitlements = @{ RHNC::->entitlements() };

my $e1 = 'virtualization_host';
my $e2 = 'provisioning_entitled';

my $ake_ref;
my %h;

# set 2 entitlements
$ak->entitlements( set => [ $e1, $e2 ] );
$ak = $ak->get( $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ake_ref = $ak->entitlements } ),
    2, "Now 2 entitlements in ak " . $ak->key );
diag( "entitlements added : " . join ", ", @$ake_ref );
%h = map { $_ => 1 } @$ake_ref;
BEGIN { $tests++; }
ok( defined $h{$e1}, "$e1 is here" );
BEGIN { $tests++; }
ok( defined $h{$e2}, "$e2 is here" );

# remove 1 entitlements
$ak->entitlements( remove => [$e1] );
$ak = $ak->get( $ak->key );

BEGIN { $tests++; }
is( scalar( @{ $ake_ref = $ak->entitlements } ),
    1, "Now 1 entitlement in ak " . $ak->key );
diag( "entitlements in ak : " . join ", ", @$ake_ref );
%h = map { $_ => 1 } @$ake_ref;
BEGIN { $tests++; }
ok( !defined $h{$e1}, "$e1 is not here" );
BEGIN { $tests++; }
ok( defined $h{$e2}, "$e2 is here" );

$ak->entitlements( remove => [$e2] );
$ak = $ak->get( $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ake_ref = $ak->entitlements } ),
    0, "Now 0 entitlements in ak " . $ak->key );

# re add 1st entitlements
$ak->entitlements( add => [] );
$ak = $ak->get( $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ak->entitlements } ),
    0, "Now 0 entitlements in ak " . $ak->key );

$ak->entitlements( add => [ $e1, $e2 ] );
$ak = $ak->get( $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ak->entitlements } ),
    2, "Now 2 entitlements in ak " . $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ake_ref = $ak->entitlements } ),
    2, "Now 2 entitlements in ak " . $ak->key );
%h = map { $_ => 1 } @$ake_ref;
BEGIN { $tests++; }
ok( defined $h{$e1}, "$e1 is here" );
BEGIN { $tests++; }
ok( defined $h{$e2}, "$e2 is here" );

$ak->entitlements( [] );
$ak = $ak->get( $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ake_ref = $ak->entitlements } ),
    0, "Now 0 entitlements in ak " . $ak->key );

$ak->entitlements( [ $e1, $e2 ] );
$ak = $ak->get( $ak->key );
BEGIN { $tests++; }
is( scalar( @{ $ake_ref = $ak->entitlements } ),
    2, "Now 2 entitlements in ak " . $ak->key );

BEGIN { $tests++; }
ok( $ak->destroy, "destroy ok" );

