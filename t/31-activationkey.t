#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::ActivationKey $RHNC::ActivationKey::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $ak = RHNC::ActivationKey->create(
    rhnc        => $rhnc,
    description => "Test activation key",
);

BEGIN { $tests++ }
is(
    $ak->description(),
    "Test activation key",
    "description ok after create " . $ak->description()
);
my $key = $ak->name();

$ak = RHNC::ActivationKey->get( $rhnc, $key );
BEGIN { $tests++ }
isa_ok( $ak, 'RHNC::ActivationKey' );

BEGIN { $tests++ }
is(
    $ak->description(),
    "Test activation key",
    "description ok after get " . $ak->description()
);

undef $ak;

$ak = RHNC::ActivationKey::get( $rhnc, $key );
BEGIN { $tests++ }
like( $ak->name, qr{ [0-9a-f-]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++ }
ok( $ak->universal_default == 0 || $ak->universal_default == 1,
    'universal_default... or not' );

BEGIN { $tests++ }
ok( $ak->destroy(), 'activation key destroyed' );

my @list;

@list = @{ $ak->list() };
BEGIN { $tests++ }
ok( @list, 'Get list : ' . scalar @list );

#foreach (@list)  { print STDERR $_->name() . "\n"; }

@list = @{  RHNC::ActivationKey::list($rhnc) };
BEGIN { $tests++ }
ok( @list, 'Get list 2 : ' . scalar @list );

#foreach (@list)  { print STDERR $_->name() . "\n"; }

BEGIN { $tests++ }
@list = @{ RHNC::ActivationKey->list($rhnc) };
ok( @list, 'Get list 3 : ' . scalar @list );

#foreach (@list)  { print STDERR $_->name() . "\n"; }

my $k  = shift @list;
my $kn = $k->name();
diag("Testing key $kn");

BEGIN { $tests++ }
$ak = $ak->get($kn);
like( $ak->{key}, qr{ [0-9a-f-]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++ }
$ak = RHNC::ActivationKey::get( $rhnc, $kn );
like( $ak->{key}, qr{ [0-9a-f-]+ }imxs, "key name defined : $ak->{key}" );

BEGIN { $tests++ }
$ak = RHNC::ActivationKey->get( $rhnc, $kn );
like( $ak->{key}, qr{ [0-9a-f-]+ }imxs, "key name defined : $ak->{key}" );

