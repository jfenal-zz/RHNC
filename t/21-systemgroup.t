#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::SystemGroup $RHNC::SystemGroup::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $sg = RHNC::SystemGroup->new(
    rhnc      => $rhnc,
    name      => "xxxRHEL5",
    description     => "System group for xxxRHEL5 servers",
);

BEGIN { $tests++ }
is( $sg->{name}, "xxxRHEL5", "name ok after new");

BEGIN { $tests++ }
is( $sg->{description}, "System group for xxxRHEL5 servers", "description ok after new");

BEGIN { $tests++ }
ok( $sg->create(), 'systemgroup created' );


BEGIN { $tests++ }
ok( $sg->destroy(), 'systemgroup destroyed' );


