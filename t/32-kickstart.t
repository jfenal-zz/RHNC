#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::Kickstart $RHNC::Kickstart::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

#$insttypes = RHNC::KickstartTree::list_install_types($rhnc);

#print Dumper $insttypes;
#print Dumper $kstrees;

# just to be sure...
BEGIN { $tests++ }
ok( RHNC::Kickstart::destroy( $rhnc, 'new-ks' ), 'kickstart new-ks destroyed if existing...');

my $ks = RHNC::Kickstart->create(
    rhnc       => $rhnc,
    label      => 'new-ks',
    name       => 'new-ks',
    server     => $rhnc->server(),
    tree_label => 'ks-rhel-x86_64-server-5-u4',
    virt_type  => 'none',
    password   => 'redhat',
);

BEGIN { $tests++ }
is( $ks->label, "new-ks", "label ok after new" );
my $key = $ks->label();

$ks = ();


$ks = RHNC::Kickstart::get( $rhnc, $key );
BEGIN { $tests++ }
like(
    $ks->label(),
    qr{ \w+ }imxs,
    "Kickstart name defined after get : $ks->{label}"
);

BEGIN { $tests++ }
ok( $ks->org_default == 0 || $ks->org_default == 1, 'org_default' );
BEGIN { $tests++ }
ok( $ks->advanced_mode == 0 || $ks->advanced_mode == 1, 'advanced_mode' );

BEGIN { $tests++ }
ok( $ks->destroy(), 'kickstart destroyed' );

=pod
my @list;

@list = $ks->list();;
BEGIN { $tests++ }
ok(@list, 'Get list : ' . scalar @list);
#foreach (@list)  { print STDERR $_->name() . "\n"; }

@list = RHNC::Kickstart::list( $rhnc );
BEGIN { $tests++ }
ok(@list, 'Get list 2 : '. scalar @list );
#foreach (@list)  { print STDERR $_->name() . "\n"; }

BEGIN { $tests++ }
@list = RHNC::Kickstart->list( $rhnc );
ok(@list, 'Get list 3 : '. scalar @list );
#foreach (@list)  { print STDERR $_->name() . "\n"; }


my $k = shift @list;
my $kn = $k->name();

BEGIN { $tests++ }
$ks = $ks->get( $kn);
like( $ks->{key}, qr{ [0-9a-f-]+ }imxs, "key name defined : $ks->{key}" );

BEGIN { $tests++ }
$ks = RHNC::Kickstart::get( $rhnc, $kn );
like( $ks->{key}, qr{ [0-9a-f-]+ }imxs, "key name defined : $ks->{key}" );

BEGIN { $tests++ }
$ks = RHNC::Kickstart->get( $rhnc, $kn);
like( $ks->{key}, qr{ [0-9a-f-]+ }imxs, "key name defined : $ks->{key}" );
=cut

