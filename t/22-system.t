#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::SystemGroup $RHNC::SystemGroup::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

# Test list()
my $slist = RHNC::System->list($rhnc);
BEGIN { $tests++ }
ok( keys %$slist > 0, "At least one system registered");

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

# compare with other ways to get list
diag("list testing");
BEGIN { $tests++ }
is_deeply( $slist, RHNC::System::list($rhnc), "RHNC::System::list");
BEGIN { $tests++ }
is_deeply( $slist,  $sys->list, '$sys->list');
BEGIN { $tests++ }
is_deeply( $slist,  $sys->list('[a-zA-Z]*'), '$sys->list regexp');

BEGIN { $tests++ }
eval { RHNC::System->list([]) };
ok( $@, "RHNC::System->list(crap) croaks");
BEGIN { $tests++ }
my $sys2 = RHNC::System->get( $rhnc, $system_id );
delete $sys2->{rhnc};
eval { $sys2->list([]) };
ok( $@, '$sys->list(crap) croaks when no rhnc present');


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

BEGIN { $tests++; }
my $id = $sys->id;
ok( RHNC::System::is_systemid($id), "system id $id looks like a system id" );
my $id2;
$id2 = RHNC::System->id( $rhnc, $sys->profile_name );

BEGIN { $tests++; }
is( $id, $id2, "RHNC::System->id is id" );
BEGIN { $tests++; }
ok( RHNC::System::is_systemid($id2), "system id $id2 looks like a system id" );

$id2 = RHNC::System::id( $rhnc, $sys->profile_name );
BEGIN { $tests++; }
is( $id, $id2, "RHNC::System::id $id2 is id" );
BEGIN { $tests++; }
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

diag("getters");
my @getters = (
    qw( release address1 address2 city state country building room
    description rack hostname osa_status base_channel running_kernel last_checkin )
);
BEGIN { $tests += 2 * 14; }
$sys->get_details;
my %get;
foreach my $method (@getters) {
    my $r = $sys->$method();
    $get{$method} = $r;
    ok( $r || $r eq '', "$method" );
}
diag("getters with satellite request");
foreach my $method (@getters) {
    my $sys2 = $sys->get( $sys->id );
    delete $sys2->{$method};
    my $r = $sys2->$method();
    is( $r, $get{$method}, "$method" );
}

diag("Testing setters");
my @setters = (
    qw( address1 address2 city state country building room description rack )
);
BEGIN { $tests += 9; }
foreach my $method (@setters) {
    my $content = 'new content';
    if ( $method eq 'country') {
        $content = 'FR';
    }
    my $r = $sys->$method( $content );
    if ($content ne 'country' ) {
        is( $sys->$method( $r ), $content , "$method(q(new content))" );
    }
}
