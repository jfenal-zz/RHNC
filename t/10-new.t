#!perl -T

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
my $av = $rhnc->apiversion();
ok($av >= 10.8, "API Version ($av) > 10.8");

BEGIN { $tests++ }
my $sv = $rhnc->systemversion();
ok($sv >= 5.3, "Satellite version ($sv) > 5.3");

