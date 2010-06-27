#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  s21-sg.t
#
#  DESCRIPTION:  test rhnc-sg
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Jérôme Fenal
#      COMPANY:  Red Hat
#      VERSION:  1.0
#      CREATED:  14/06/2010
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use lib qw( . lib lib/RHNC );
use Cwd qw( abs_path );
use Data::Dumper;

# Lamely copy/pasted from Array::Utils by Sergei A. Fedorov
sub array_diff {
    my %e = map { $_ => undef } @{ $_[1] };
    return @{
        [
            ( grep { ( exists $e{$_} ) ? ( delete $e{$_} ) : (1) } @{ $_[0] } ),
            keys %e
        ]
      };
}

use Test::More;    # last test to print
my $script = 'rhnc-sg';

eval "use Test::Script::Run qw(:all)";
plan skip_all => "Test::Script::Run required for testing $script" if $@;

my $s;
for my $d (qw( . script ../script )) {
    $s = "$d/$script" if -f "$d/$script";
}

$s = abs_path $s;

my $tests;
plan tests => $tests;

BEGIN { $tests++; }
ok( defined $s, "script to test found : $s" );

BEGIN { $tests++; }
run_ok( $s, [], "$script (no arg)" );

BEGIN { $tests++; }
run_ok( $s, [qw(wrong command)], "$script (wrong command)" );

BEGIN { $tests++; }
run_ok( $s, [qw( help )], "$script help" );

BEGIN { $tests++; }
like( last_script_stdout(), qr{ USAGE }msix, "$script help gives man page" );

BEGIN { $tests++; }
run_ok( $s, ['list'], "$script list" );

BEGIN { $tests++; }
unlike(
    last_script_stdout(),
    qr{Total: \d+ system groups}ims,
    "$script list doesn't give Total"
);

my @groups = split /\n/, last_script_stdout();
my $biggroup = $groups[-1];

BEGIN { $tests++; }
run_ok( $s, [ 'list', '-v' ], "$script list -v" );

BEGIN { $tests++; }
like(
    last_script_stdout(),
    qr{Total: \d+ system groups}ims,
    "$script list -v gives Total"
);

BEGIN { $tests++; }
run_ok( $s, [ 'list_systems', $biggroup ], "$script list_systems $biggroup" );
my @systems = split /\n/, last_script_stdout();
my $add_systems = join ',', @systems;

BEGIN { $tests++; }
run_ok( $s, [ 'get', $biggroup ], "$script get $biggroup" );

BEGIN { $tests++; }
like(
    last_script_stdout(),
    qr{ \A $biggroup : }msix,
    "$script get $biggroup dumps $biggroup"
);

BEGIN { $tests++; }
run_not_ok( $s, ['create'], "$script create" );

my $newgroup = 'xxxTestGroup';    # TODO : randomize name
BEGIN { $tests++; }
run_ok(
    $s,
    [ 'destroy', $newgroup ],
    "$script destroy $newgroup (non existing) does not fail "
);
BEGIN { $tests++; }
like(
    last_script_stdout(),
    qr{No such system group $newgroup}ims,
    "$script destroy $newgroup carps that it does not exist"
);

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'create', $newgroup, '-d', 'Test group' ],
    "$script create $newgroup (no systems)"
);

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'as', $newgroup, '-s', $add_systems ],
    "$script add_systems $newgroup -s $add_systems"
);

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'as', $newgroup, ],
    "$script add_systems $newgroup (no systems) returns ok"
);

BEGIN { $tests++; }
run_not_ok( $s, [ 'as', $newgroup, '-s' ], "$script add_systems $newgroup -s" );

BEGIN { $tests++; }
run_ok( $s, [ 'ls', $newgroup ], "$script list_systems $newgroup" );
my @added_systems = split /\n/, last_script_stdout();

BEGIN { $tests++; }
ok(
    !array_diff( \@added_systems, \@systems ),
    "same systems in $biggroup & $newgroup"
);

#is( scalar @systems, scalar @added_systems, "same number of systems between $biggroup & $newgroup");

BEGIN { $tests++; }
run_ok( $s, [ 'destroy', $newgroup ], "$script destroy $newgroup" );

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'create', $newgroup, '-s', $add_systems ],
    "$script create $newgroup -s $add_systems"
);

BEGIN { $tests++; }
run_ok( $s, [ 'ls', $newgroup ], "$script list_systems $newgroup" );
@added_systems = split /\n/, last_script_stdout();

BEGIN { $tests++; }
ok(
    !array_diff( \@added_systems, \@systems ),
    "same systems in $biggroup & $newgroup"
);

my @systems2remove;
push @systems2remove, shift @added_systems;    # remove one system from group
push @systems2remove, shift @added_systems;    # remove one system from group
my $rm_systems = join ',', @systems2remove;

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'rs', $newgroup, '-s', $rm_systems ],
    "$script rm_systems $newgroup -s $rm_systems"
);

BEGIN { $tests++; }
run_ok( $s, [ 'rs', $newgroup, ], "$script rm_systems $newgroup (no option) succeeds" );

BEGIN { $tests++; }
run_not_ok( $s, [ 'rs', $newgroup, '-s' ], "$script rm_systems $newgroup -s (unknown option) fails" );

BEGIN { $tests++; }
run_not_ok( $s, [ 'rs', $newgroup, '-X' ], "$script rm_systems $newgroup -X (unknown option) fails" );


BEGIN { $tests++; }
run_ok( $s, [ 'ls', $newgroup ], "$script list_systems $newgroup" );
my @syslist = split /\n/, last_script_stdout();

BEGIN { $tests++; }
ok( !array_diff( \@added_systems, \@syslist ),
    "supposed system list after removal same as actual system list" );


BEGIN { $tests++; }
run_ok( $s, [ 'destroy', $newgroup ], "$script destroy $newgroup" );


