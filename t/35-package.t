#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::Package $RHNC::Package::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

#$insttypes = RHNC::PackageTree::list_install_types($rhnc);

#print Dumper $insttypes;
#print Dumper $kstrees;

# just to be sure...

#$p = RHNC::Package::get( $rhnc, 1 );
#delete $p->{rhnc};
#diag( Dumper $p );

my ( $name, $version, $release, $arch );
( $name, $version, $release, $arch ) =
  RHNC::Package::split_package_name('kernel-doc-2.6.33.5-124.fc13.noarch');

BEGIN { $tests++; }
ok( RHNC::Package::list_arch_canon(), "RHNC::Package::list_arch_canon returns something" );
BEGIN { $tests++; }
ok( RHNC::Package::list_arch_canon(1), "RHNC::Package::list_arch_canon(1) returns something" );

BEGIN { $tests += 25; }
is( $name,    'kernel-doc', "split_package_name: name" );
is( $version, '2.6.33.5',   "split_package_name: version" );
is( $release, '124.fc13',   "split_package_name: release" );
is( $arch,    'noarch',     "split_package_name: arch" );
is(
    RHNC::Package::join_package_name(
        {
            name    => $name,
            version => $version,
            release => $release,
            arch    => $arch
        }
    ),
    'kernel-doc-2.6.33.5-124.fc13.noarch',
    "join ok"
);

( $name, $version, $release, $arch ) =
  RHNC::Package::split_package_name('kernel-doc-2.6.33.5-124.fc13');
is( $name,    'kernel-doc', "split_package_name: name" );
is( $version, '2.6.33.5',   "split_package_name: version" );
is( $release, '124.fc13',   "split_package_name: release" );
ok( !defined $arch, "arch not defined" );
is(
    RHNC::Package::join_package_name(
        {
            name    => $name,
            version => $version,
            release => $release,
            arch    => $arch
        }
    ),
    'kernel-doc-2.6.33.5-124.fc13',
    "join ok"
);

( $name, $version, $release, $arch ) =
  RHNC::Package::split_package_name('kernel-doc.noarch');
is( $name, 'kernel-doc', "split_package_name: name" );
ok( !defined $version, "arch not defined" );
ok( !defined $release, "arch not defined" );
is( $arch, 'noarch', "split_package_name: arch" );
is(
    RHNC::Package::join_package_name(
        {
            name    => $name,
            version => $version,
            release => $release,
            arch    => $arch
        }
    ),
    'kernel-doc.noarch',
    "join ok"
);

( $name, $version, $release, $arch ) =
  RHNC::Package::split_package_name('bogus-9-norel.noarch');
is( $name, 'bogus-9-norel', "split_package_name: name" );
ok( !defined $version, "arch not defined" );
ok( !defined $release, "arch not defined" );
is( $arch, 'noarch', "split_package_name: arch" );
is(
    RHNC::Package::join_package_name(
        {
            name    => $name,
            version => $version,
            release => $release,
            arch    => $arch
        }
    ),
    'bogus-9-norel.noarch',
    "join ok"
);

( $name, $version, $release, $arch ) =
  RHNC::Package::split_package_name('bogus-9.noarch');
is( $name, 'bogus-9', "split_package_name: name" );
ok( !defined $version, "arch not defined" );
ok( !defined $release, "arch not defined" );
is( $arch, 'noarch', "split_package_name: arch" );
is(
    RHNC::Package::join_package_name(
        {
            name    => $name,
            version => $version,
            release => $release,
            arch    => $arch
        }
    ),
    'bogus-9.noarch',
    "join ok"
);

BEGIN { $tests += 6; }

is(
    RHNC::Package::join_package_name(
        {
            name    => 'kernel-doc',
            version => '2.6.33.5',
            release => '124.fc13',
            arch    => 'noarch',
        }
    ),
    'kernel-doc-2.6.33.5-124.fc13.noarch',
    "join ok"
);

is(
    RHNC::Package::join_package_name(
        {
            name    => 'kernel-doc',
            version => '2.6.33.5',
            release => '124.fc13',
        }
    ),
    'kernel-doc-2.6.33.5-124.fc13',
    "join ok"
);

is(
    RHNC::Package::join_package_name(
        {
            name    => 'kernel-doc',
            version => '2.6.33.5',
            arch    => 'noarch',
        }
    ),
    'kernel-doc.noarch',
    "join ok"
);

is(
    RHNC::Package::join_package_name(
        {
            name    => 'kernel-doc',
            release => '124.fc13',
            arch    => 'noarch',
        }
    ),
    'kernel-doc.noarch',
    "join ok"
);
is(
    RHNC::Package::join_package_name(
        {
            name => 'kernel-doc',
            arch => 'not_a_valid_arch',
        }
    ),
    'kernel-doc',
    "join ok"
);
my $p;
eval { $p = RHNC::Package::join_package_name("no name"); };
ok( $@, "croak if no name in join_package_name" );

#
# Let's get some packages from channels
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
#my $p1 = RHNC::Package->get($rhnc, $plist->[0]->id);
#my $p2 = RHNC::Package->get($rhnc, $plist->[1]->id);
#my $p3 = RHNC::Package->get($rhnc, $plist->[2]->id);
my $p1 = $plist->[0];
my $p2 = $plist->[1];
my $p3 = $plist->[2];
diag("Using ". $p1->nvra);
diag("Using ". $p2->nvra);
diag("Using ". $p3->nvra);

BEGIN { $tests += 6; }
ok( defined $p1->id,      "p1 id defined" );
ok( defined $p1->nvra,    "p1 nvra defined" );
ok( defined $p1->name,    "p1 name defined" );
ok( defined $p1->version, "p1 version defined" );
ok( defined $p1->release, "p1 release defined" );
ok( defined $p1->arch,    "p1 arch defined" );

my $p4 = RHNC::Package->get( $rhnc, $p1->id );
BEGIN { $tests += 5; }
is( $p1->name,    $p4->name,    "ident name" );
is( $p1->version, $p4->version, "ident version" );
is( $p1->release, $p4->release, "ident release" );
is( $p1->arch,    $p4->arch,    "ident arch" );
is( $p1->nvra,    $p4->nvra,    "ident nvra" );

my $p5 = RHNC::Package::get( $rhnc, $p2->id );
BEGIN { $tests += 5; }
is( $p2->name,    $p5->name,    "ident name" );
is( $p2->version, $p5->version, "ident version" );
is( $p2->release, $p5->release, "ident release" );
is( $p2->arch,    $p5->arch,    "ident arch" );
is( $p2->nvra,    $p5->nvra,    "ident nvra" );

my $p6 = $p2->get( $p3->id );
BEGIN { $tests += 5; }
is( $p3->name,    $p6->name,    "ident name" );
is( $p3->version, $p6->version, "ident version" );
is( $p3->release, $p6->release, "ident release" );
is( $p3->arch,    $p6->arch,    "ident arch" );
is( $p3->nvra,    $p6->nvra,    "ident nvra" );

shift @channels; # FIXME let's hope we have more than one channel
PKG2:
foreach my $c (@channels) {
    if ( @{ $plist = $c->list_packages() } ) {
        diag( 'Using channel : ' . $c->name );
        last PKG2;
    }
}

# 2. get 3 packages
$p1 = $plist->[0];
$p2 = $plist->[1];
$p3 = $plist->[2];
diag("Using ". $p1->nvra);
diag("Using ". $p2->nvra);
diag("Using ". $p3->nvra);

BEGIN { $tests += 6; }
ok( defined $p1->id,      "p1 id defined" );
ok( defined $p1->nvra,    "p1 nvra defined" );
ok( defined $p1->name,    "p1 name defined" );
ok( defined $p1->version, "p1 version defined" );
ok( defined $p1->release, "p1 release defined" );
ok( defined $p1->arch,    "p1 arch defined" );

my $p4 = RHNC::Package->get( $rhnc, $p1->id );
BEGIN { $tests += 5; }
is( $p1->name,    $p4->name,    "ident name" );
is( $p1->version, $p4->version, "ident version" );
is( $p1->release, $p4->release, "ident release" );
is( $p1->arch,    $p4->arch,    "ident arch" );
is( $p1->nvra,    $p4->nvra,    "ident nvra" );

my $p5 = RHNC::Package::get( $rhnc, $p2->id );
BEGIN { $tests += 5; }
is( $p2->name,    $p5->name,    "ident name" );
is( $p2->version, $p5->version, "ident version" );
is( $p2->release, $p5->release, "ident release" );
is( $p2->arch,    $p5->arch,    "ident arch" );
is( $p2->nvra,    $p5->nvra,    "ident nvra" );

my $p6 = $p2->get( $p3->id );
BEGIN { $tests += 5; }
is( $p3->name,    $p6->name,    "ident name" );
is( $p3->version, $p6->version, "ident version" );
is( $p3->release, $p6->release, "ident release" );
is( $p3->arch,    $p6->arch,    "ident arch" );
is( $p3->nvra,    $p6->nvra,    "ident nvra" );

