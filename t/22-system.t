#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::SystemGroup $RHNC::SystemGroup::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $slist = RHNC::System->list($rhnc);

my $system_id = ( keys %$slist )[0];

BEGIN { $tests++ }
ok( RHNC::System::is_systemid($system_id), 'id ok ' . $system_id );

my $sys;
BEGIN { $tests++ }
$sys = RHNC::System::get( $rhnc, $system_id );
isa_ok( $sys, 'RHNC::System', "object created is indeed a RHNC::System" );
#diag( $sys->as_string );
BEGIN { $tests++ }
$sys = RHNC::System->get( $rhnc, $system_id );
isa_ok( $sys, 'RHNC::System', "object created is indeed a RHNC::System" );
#diag( $sys->as_string );

BEGIN { $tests++ }
$sys = $sys->get($system_id);
isa_ok( $sys, 'RHNC::System', "object created is indeed a RHNC::System" );
#diag( $sys->as_string );

# Return and change profile_name
diag("profile_name testing");

BEGIN { $tests++ }
my $pname    = $sys->profile_name;
my $newpname = "just-a-random-profile-name";
my $pname2   = $sys->profile_name($newpname);
ok( $pname eq $pname2, "profile_name(value) returns old value $pname" );

BEGIN { $tests++ }
$pname2 = $sys->profile_name($pname);
ok( $newpname eq $pname2, "profile_name(value) returns old value $pname2" );

BEGIN { $tests++ }
$sys = RHNC::System::get( $rhnc, $pname );
isa_ok( $sys, 'RHNC::System', "object created is indeed a RHNC::System" );

BEGIN { $tests++ }
$sys = RHNC::System->get( $rhnc, $pname );
isa_ok( $sys, 'RHNC::System', "object created is indeed a RHNC::System" );

BEGIN { $tests++ }
$sys = $sys->get($pname);
isa_ok( $sys, 'RHNC::System', "object created is indeed a RHNC::System" );

