#!perl -T

use Test::More tests => 7;

BEGIN {
	use_ok( 'RHNC::Session' );
	use_ok( 'RHNC::Client' );
	use_ok( 'RHNC::Package' );
	use_ok( 'RHNC::Channel' );
	use_ok( 'RHNC::Kickstart' );
	use_ok( 'RHNC::System' );
	use_ok( 'RHNC::SystemGroup' );
}

diag( "Testing RHNC::Session $RHNC::Session::VERSION, Perl $], $^X" );
