#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::ActivationKey $RHNC::ActivationKey::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $ak;

BEGIN { $tests += 6; }
$ak = RHNC::ActivationKey::new( description => "Test activation key", );
isa_ok( $ak, 'RHNC::ActivationKey',
    "RHNC::ActivationKey::new leads to an object" );
is( $ak->description, "Test activation key", "and description is fine" );

$ak = RHNC::ActivationKey->new( description => "Test activation key", );
isa_ok( $ak, 'RHNC::ActivationKey',
    "RHNC::ActivationKey->new leads to an object" );
is( $ak->description, "Test activation key", "and description is fine" );

$ak = $ak->new( description => "Test activation key", );
isa_ok( $ak, 'RHNC::ActivationKey',
    "RHNC::ActivationKey->new leads to an object" );
is( $ak->description, "Test activation key", "and description is fine" );

my $key;

# ----------------

BEGIN { $tests++; }
ok(
    $ak = RHNC::ActivationKey->create(
        rhnc        => $rhnc,
        description => "Test activation key"
    ),
    "->create returns something"
);
$key = $ak->name();

BEGIN { $tests++; }
isa_ok( $ak, 'RHNC::ActivationKey' );
BEGIN { $tests++; }
is(
    $ak->description(),
    "Test activation key",
    "description ok after create " . $ak->description()
);

$ak = RHNC::ActivationKey->get( $rhnc, $key );
BEGIN { $tests++; }
isa_ok( $ak, 'RHNC::ActivationKey', "isa after get" );
BEGIN { $tests++; }
is(
    $ak->description(),
    "Test activation key",
    "description ok after create " . $ak->description()
);
BEGIN { $tests++; }
ok( $ak->destroy, "destroy ok" );

BEGIN { $tests++; }
is(
    $ak->description(),
    "Test activation key",
    "description ok after get " . $ak->description()
);

# ----------------

BEGIN { $tests++; }
ok(
    $ak = RHNC::ActivationKey::create(
        rhnc              => $rhnc,
        description       => "Test activation key",
        universal_default => 1
    ),
    "->create returns something"
);
$key = $ak->name();

BEGIN { $tests++; }
isa_ok( $ak, 'RHNC::ActivationKey' );
BEGIN { $tests++; }
is(
    $ak->description(),
    "Test activation key",
    "description ok after create " . $ak->description()
);

$ak = RHNC::ActivationKey->get( $rhnc, $key );
BEGIN { $tests++; }
isa_ok( $ak, 'RHNC::ActivationKey', "isa after get" );
BEGIN { $tests++; }
is(
    $ak->description(),
    "Test activation key",
    "description ok after create " . $ak->description()
);
BEGIN { $tests++; }
is( $ak->universal_default, 1, 'universal_default' );

my $newak;
BEGIN { $tests++; }
ok(
    $newak = $ak->create( rhnc => $rhnc, description => "Test activation key" ),
    "->create returns something"
);
$key = $newak->name();
BEGIN { $tests++; }
ok( $ak->destroy, "destroy ok" );
undef $ak;

BEGIN { $tests++; }
isa_ok( $newak, 'RHNC::ActivationKey' );
BEGIN { $tests++; }
is(
    $newak->description(),
    "Test activation key",
    "description ok after create " . $newak->description()
);
$ak = RHNC::ActivationKey->get( $rhnc, $key );
BEGIN { $tests++; }
isa_ok( $ak, 'RHNC::ActivationKey', "isa after get" );
BEGIN { $tests++; }
is(
    $ak->description(),
    "Test activation key",
    "description ok after create " . $ak->description()
);
$key = $ak->name();
BEGIN { $tests++; }
is( $ak->universal_default, 0, 'universal_default' );

# ----------------
undef $ak;

$ak = RHNC::ActivationKey->get( $rhnc, $key );
BEGIN { $tests++; }
like( $ak->name, qr{ [0-9a-f-]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++ }
ok( $ak->destroy(), 'activation key destroyed' );

my @list;

@list = @{ $ak->list() };
BEGIN { $tests++; }
ok( @list, 'Get list : ' . scalar @list );

#foreach (@list)  { print STDERR $_->name() . "\n"; }

@list = @{ RHNC::ActivationKey::list($rhnc) };
BEGIN { $tests++; }
ok( @list, 'Get list 2 : ' . scalar @list );

#foreach (@list)  { print STDERR $_->name() . "\n"; }

BEGIN { $tests++; }
@list = @{ RHNC::ActivationKey->list($rhnc) };
ok( @list, 'Get list 3 : ' . scalar @list );

#foreach (@list)  { print STDERR $_->name() . "\n"; }

my $k  = shift @list;
my $kn = $k->name();
diag("Testing key $kn");

BEGIN { $tests++; }
$ak = $ak->get($kn);
like( $ak->{key}, qr{ [0-9a-f-_]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++; }
$ak = RHNC::ActivationKey::get( $rhnc, $kn );
like( $ak->{key}, qr{ [0-9a-f-_]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++; }
$ak = RHNC::ActivationKey->get( $rhnc, $kn );
like( $ak->{key}, qr{ [0-9a-f-_]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++; }
my $oak = RHNC::ActivationKey::create(
    rhnc              => $rhnc,
    description       => "Test activation key",
    universal_default => 1,
);
isa_ok( $oak, 'RHNC::ActivationKey',
    "Create a new key via RHNC::ActivationKey::create" );
BEGIN { $tests++; }
$ak = $oak->get( $oak->name() );
is( $oak->name(), $oak->name(),
    "Newly created key name same after create then get" );

BEGIN { $tests++; }
ok( $oak->destroy, "destroy ok" );

#
# packages
#

# 1. get a channel with packages
my @channels = @{ RHNC::Channel->list($rhnc) };
my $plist;
PKG:
foreach my $c (@channels) {
    if ( @{ $plist = $c->latest_packages() } ) {
        diag( 'Using channel : ' . $c->name );
        last PKG;
    }
}

# 2. get 3 packages
my $p1_name = $plist->[0]->name();
my $p2_name = $plist->[1]->name();
my $p3_name = $plist->[2]->name() . q(.) . $plist->[2]->arch();
diag("p1 : $p1_name");
diag("p2 : $p2_name");
diag("p3 : $p3_name");
$ak = RHNC::ActivationKey::create(
    rhnc         => $rhnc,
    description  => "Test activation key",
    entitlements => [qw( provisioning_entitled )],   # necessary to add packages
);
BEGIN { $tests++; }
isa_ok( $ak, 'RHNC::ActivationKey',
    "Create a new key via RHNC::ActivationKey::create" );
diag( "Addind packages to " . $ak->name );
my $prev;
$prev = $ak->packages( add => [ $p1_name, $p2_name, $p3_name ] );

BEGIN { $tests++; }
is( scalar @$prev, 0, "previous packages list empty" );

diag("Get again activation key");
$ak = $ak->get( $ak->name );
my %pname = map { $_ => 1 } @{ $ak->packages };
BEGIN { $tests += 3; }
ok( defined $pname{$p1_name}, "$p1_name still present" );
ok( defined $pname{$p2_name}, "$p2_name still present" );
ok(
    defined $pname{ $plist->[2]->name() },
    "$p3_name still present, but arch removed"
);    # TODO : check if true at all times... ?

$prev  = $ak->packages( remove => [ $p1_name, $p2_name ] );
$ak    = $ak->get( $ak->name );
%pname = map { $_ => 1 } @{ $ak->packages };
BEGIN { $tests++; }
is( scalar keys %pname, 1, "Only 1 package left" );
BEGIN { $tests++; }
ok(
    defined $pname{ $plist->[2]->name() },
    "$p3_name still present, but arch removed"
);    # TODO : check if true at all times... ?

$prev  = $ak->packages( [ $p1_name, $p2_name ] );
$ak    = $ak->get( $ak->name );
%pname = map { $_ => 1 } @{ $ak->packages };
BEGIN { $tests += 2; }
ok( defined $pname{$p1_name}, "$p1_name still present" );
ok( defined $pname{$p2_name}, "$p2_name still present" );

$prev  = $ak->packages( set => [ $p1_name, $p3_name ] );
$ak    = $ak->get( $ak->name );
%pname = map { $_ => 1 } @{ $ak->packages };
BEGIN { $tests += 2; }
ok( defined $pname{$p1_name}, "$p1_name still present" );
ok(
    defined $pname{ $plist->[2]->name() },
    "$p3_name still present, but arch removed"
);    # TODO : check if true at all times... ?


# usage limit
diag("testing usage limit");
$key = $ak->name;
diag "Usage limit for " . $key . " is " . $ak->usage_limit;
$ak->usage_limit(20);
$ak = $ak->get($key);
BEGIN { $tests++; }
is( $ak->usage_limit, 20, "usage_limit" );

# universal_default
diag("testing universal_default");
$ak->universal_default(1);
$ak = $ak->get($key);
BEGIN { $tests++; }
ok( $ak->universal_default, "universal_default 1" );
$ak->universal_default(0);
$ak = $ak->get($key);
BEGIN { $tests++; }
ok( !$ak->universal_default, "universal_default 0" );

BEGIN { $tests++; }
ok( $ak->destroy, "destroy ok" );
