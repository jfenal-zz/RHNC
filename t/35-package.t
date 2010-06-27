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


my   ( $name, $version, $release, $arch );
( $name, $version, $release, $arch ) = RHNC::Package::split_package_name( 'kernel-doc-2.6.33.5-124.fc13.noarch' );

diag( Dumper \%RHNC::Package::arch_canon) ;
BEGIN { $tests+=7; }
is( $name, 'kernel-doc', "split_package_name: name");
is( $version, '2.6.33.5', "split_package_name: version");
is( $release, '124.fc13', "split_package_name: release");
is( $arch, 'noarch', "split_package_name: arch");

( $name, $version, $release ) = RHNC::Package::split_package_name( 'kernel-doc-2.6.33.5-124.fc13' );
is( $name, 'kernel-doc', "split_package_name: name");
is( $version, '2.6.33.5', "split_package_name: version");
is( $release, '124.fc13', "split_package_name: release");

