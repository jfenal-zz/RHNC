#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::Errata $RHNC::Errata, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $mycve = 'CVE-2008-2936'; # postfix security issue, common to RHEL3, RHEL4, and RHEL5
my $myerr = 'RHSA-2008:0839'; # corresponding errata


BEGIN { $tests++; }
my $l = RHNC::Errata->find_by_cve( $rhnc, $mycve );
isa_ok( $l, 'ARRAY', 'list is a array ref' );

BEGIN { $tests++; }
my $errata = $l->[0];
isa_ok( $errata, 'RHNC::Errata', 'and first member is RHNC::Errata' );

my @methods;

BEGIN {
    @methods = (qw( id advisory_name advisory_synopsis advisory_type  ));
    $tests += scalar @methods;
}
foreach my $m (@methods) {
    diag "Testing method $m";
    my $v = $errata->$m();
    if ( ref $v && ref $v =~ m{ \A Frontier:: }mxs ) {
        $v = $v->value();
    }
    ok( defined($v), "$m is $v" );
}

