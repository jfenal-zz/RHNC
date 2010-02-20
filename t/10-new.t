#!perl -T

use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use RHNC::Session;


#BEGIN { use_ok( 'RHNC::Session' ); } 

diag( "Testing RHNC::Session $RHNC::Session::VERSION, Perl $], $^X" );

my $tests;

plan tests => $tests;

my $rhnc = RHNC::Session->new( config => "$ENV{HOME}/.rhnrc" );


BEGIN { $tests++ }
is($rhnc->version, 0.01, "Version is ".$rhnc->version);

#use Data::Dumper; print STDERR Dumper $rhnc;
