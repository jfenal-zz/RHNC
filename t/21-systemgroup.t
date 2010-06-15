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
    name      => 'xxxRHEL5',
    description     => 'System group for xxxRHEL5 servers',
);

BEGIN { $tests++ }
is( $sg->{name}, 'xxxRHEL5', 'name ok after new' );

BEGIN { $tests++ }
is( $sg->{description}, 'System group for xxxRHEL5 servers', 'description ok after new');

BEGIN { $tests++ }
ok( $sg->create(), 'systemgroup created' );


my $ssg1 = RHNC::SystemGroup->get( $rhnc, 'xxxRHEL5');
BEGIN { $tests++ }
is( $ssg1->{name}, 'xxxRHEL5', 'name ok after new');
BEGIN { $tests++ }
is( $ssg1->{description}, 'System group for xxxRHEL5 servers', 'description ok after new');


my $ssg2 = RHNC::SystemGroup->get( $rhnc, 'xxxRHEL5');
BEGIN { $tests++ }
is( $ssg2->{name}, 'xxxRHEL5', 'name ok after new');
BEGIN { $tests++ }
is( $ssg2->{description}, 'System group for xxxRHEL5 servers', 'description ok after new');

my $sg2 = $ssg2->new(
    rhnc => $rhnc,
    name      => 'yyyRHEL5',
    description     => 'System group for yyyRHEL5 servers',
);
BEGIN { $tests++ }
ok( $sg2->create(), 'systemgroup created' );


BEGIN { $tests++ }
ok( $sg->destroy(), 'systemgroup destroyed' );

BEGIN { $tests++ }
ok( $sg2->destroy(), 'systemgroup destroyed' );


