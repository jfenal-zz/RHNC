#!perl -T

use Test::More tests => 7;

BEGIN {
	use_ok( 'RHN::Session' );
	use_ok( 'RHN::Client' );
	use_ok( 'RHN::Package' );
	use_ok( 'RHN::Channel' );
	use_ok( 'RHN::Kickstart' );
	use_ok( 'RHN::System' );
	use_ok( 'RHN::SystemGroup' );
}

diag( "Testing RHN::Session $RHN::Session::VERSION, Perl $], $^X" );
