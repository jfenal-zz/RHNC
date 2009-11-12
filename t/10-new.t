#!perl -T

use Test::More;

use lib qw( . lib lib/RHN );
use RHN::Session;


#BEGIN { use_ok( 'RHN::Session' ); } 

diag( "Testing RHN::Session $RHN::Session::VERSION, Perl $], $^X" );

my $tests;

plan tests => $tests;

my $rhnc = RHN::Session->new( config => "$ENV{HOME}/.rhnrc" );


BEGIN { $tests++ }
is($rhnc->version, 0.01, "Version is ".$rhnc->version);

#use Data::Dumper; print STDERR Dumper $rhnc;
