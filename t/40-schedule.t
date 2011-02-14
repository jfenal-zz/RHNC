#!/usr/bin/perl
use Test::More;

use lib qw( . lib lib/RHNC );
use RHNC;
use Data::Dumper;

diag("Testing RHNC::SystemGroup $RHNC::SystemGroup::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

BEGIN { $tests++; }
my $l = RHNC::Schedule->actions($rhnc, 'all');
isa_ok( $l, 'ARRAY', 'list is a array ref' );

my $action1 = $l->[0];

my @methods;

BEGIN {
    @methods = (qw( id type scheduler name earliest ));
    $tests += scalar @methods;
}
foreach my $m (@methods) {
    my $v = $action1->$m();
    if ( $m eq 'earliest' ) {
        $v = $v->value();
    }
    if (! defined $v) {
        $v = '(not defined)';
    }
    ok( defined($v), "$m is $v" );
}

BEGIN { $tests++; }
ok( $action1->cancel(), "cancel " . $action1->id() );
