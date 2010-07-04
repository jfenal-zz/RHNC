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

diag( Dumper \%RHNC::Package::arch_canon );
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

BEGIN { $tests+= 6; }

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
            name    => 'kernel-doc',
            arch    => 'not_a_valid_arch',
        }
    ),
    'kernel-doc',
    "join ok"
);
my $p;
eval { $p = RHNC::Package::join_package_name( "no name" ); };
ok( $@, "croak if no name in join_package_name");


