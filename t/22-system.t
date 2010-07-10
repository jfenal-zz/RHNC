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

BEGIN { $tests += 4; }
my $id = $sys->id;
like( $id, qr/\d+/, "system id is a number" );
is(
    $id,
    RHNC::System->id( $rhnc, $sys->profile_name ),
    "RHNC::System->id is id"
);
is(
    $id,
    RHNC::System::id( $rhnc, $sys->profile_name ),
    "RHNC::System::id is id"
);
ok( !RHNC::System::id( [] ), "RHNC::System::id( crap )" );

BEGIN { $tests += 3; }
my $e = $sys->base_entitlement;
diag("base_entitlement: $e");
ok(
    (
             $e eq 'enterprise_entitled'
          || $e eq 'sw_mgr_entitled'
          || $e eq 'unentitled'
    ),
    "base_entitlement"
);
ok( $e eq $sys->base_entitlement('sw_mgr_entitled'), "base_entitlement" );
ok( $sys->base_entitlement($e), "base_entitlement" );

BEGIN { $tests += 3; }
my $au = $sys->auto_update;
diag("auto_update: $e");
ok( $au eq 0 || $au, "auto_update" );
ok( $au eq $sys->auto_update( !$au ), "auto_update" );
ok( $sys->auto_update($au), "auto_update" );

BEGIN { $tests += 3; }
my $au = $sys->lock_status;
diag("lock_status: $e");
ok( $au eq 0 || $au, "lock_status" );
ok( $au eq $sys->lock_status( !$au ), "lock_status" );
ok( $sys->lock_status($au), "lock_status" );

# getters only
BEGIN { $tests += 3; }
ok( $sys->release, "release" );

my @getters = (
    qw( release address1 address2 city state country building room rack hostname osa_status base_channel running_kernel )
);
BEGIN { $tests += 11; }
$sys->get_details;
foreach my $method (@getters) {
    my $r = $sys->$method();
    ok( $r || $r eq '', "$method" );
}

