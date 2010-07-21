#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::ConfigChannel $RHNC::ConfigChannel::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();


BEGIN { $tests += 4; }
my $cc1 = RHNC::ConfigChannel::new( label => 'test-config-channel' );
isa_ok( $cc1, 'RHNC::ConfigChannel', "RHNC::ConfigChannel::new leads to an object" );
is( $cc1->label, "test-config-channel", "and label is fine" );
is( $cc1->name, "test-config-channel", "and name is fine" );
is( $cc1->description, "test-config-channel", "and description is fine" );

BEGIN { $tests += 4; }
my $cc2 = RHNC::ConfigChannel::new( label => 'test-config-channel2', name => "Name test-config-channel2", description => "Description test-config-channel2" );
isa_ok( $cc2, 'RHNC::ConfigChannel', "RHNC::ConfigChannel::new leads to an object" );
is( $cc2->label, "test-config-channel2", "and label is fine" );
is( $cc2->name, "Name test-config-channel2", "and name is fine" );
is( $cc2->description, "Description test-config-channel2", "and description is fine" );

BEGIN { $tests += 4; }
my $cc3 = $cc2->new( label => 'test-config-channel3' );
isa_ok( $cc3, 'RHNC::ConfigChannel', "RHNC::ConfigChannel::new leads to an object" );
is( $cc3->label, "test-config-channel3", "and label is fine" );
is( $cc3->name, "test-config-channel3", "and name is fine" );
is( $cc3->description, "test-config-channel3", "and description is fine" );

# ----------------
my @ccl = @{ RHNC::ConfigChannel->list( $rhnc); };
my $cc;
foreach my $i ( @ccl ) {
    if ($i->label eq "test-config-channel" ){
        $cc = $i;
    }
}
if ( defined $cc ) {
    diag "test-config-channel exists";
}
else {
    $cc = RHNC::ConfigChannel->create( rhnc        => $rhnc, label => "test-config-channel",)

}
BEGIN { $tests++; }
isa_ok(
    $cc, 'RHNC::ConfigChannel', "list or create returns a RHNC::ConfigChannel object"
);

my $label = $cc->label();

#
# setters
#
my $old;
my $new = "new content";
$old =  $cc->name( $new );
BEGIN { $tests++; }
is( $cc->name, $new, "name setter works");
BEGIN { $tests++; }
is( $new, $cc->name($old), "name setter works again");
BEGIN { $tests++; }
is( $old, $cc->name($old), "name setter works again");

$old =  $cc->description( $new );
BEGIN { $tests++; }
is( $cc->description, $new, "description setter works");
BEGIN { $tests++; }
is( $new, $cc->description($old), "description setter works again");
BEGIN { $tests++; }
is( $old, $cc->description($old), "description setter works again");


