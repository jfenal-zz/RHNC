#!perl

use strict;
use warnings;
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;


#BEGIN { use_ok( 'RHNC::Session' ); } 

diag( "Testing RHNC::Session $RHNC::Session::VERSION, Perl $], $^X" );

my $tests;

plan tests => $tests;

my $rhnc = RHNC::Session->new( config => "$ENV{HOME}/.rhnrc" );


BEGIN { $tests++ }
is($rhnc->version, 0.01, "Version is ".$rhnc->version);

BEGIN { $tests++ }
my ($avmaj, $avmin) = split /\./, $rhnc->apiversion();
ok( ($avmaj == 10  && $avmin >= 8) || $avmaj > 10, "API Version ($avmaj.$avmin) > 10.8");

BEGIN { $tests++ }
my ($svmaj, $svmin) = split /\./, $rhnc->systemversion();
ok(($svmaj == 5 && $svmin >= 3) || $svmaj > 5 , "Satellite version ($svmaj.$svmin) > 5.3");

