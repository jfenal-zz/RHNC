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

my ( $rc, $stdout, $stderr );

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
$stdout = last_script_stdout();
unlike(
    $stdout,
    qr{Total: \d+ system groups}ims,
    "$script list doesn't give Total"
);

my @groups = split /\n/, $stdout;
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
run_ok(
    $s,
    [ 'create', 'xxxTestGroup', '-d', 'Test group' ],
    "$script create xxxTestGroup (no systems)"
);

BEGIN { $tests++; }
run_ok( $s, [ 'destroy', 'xxxTestGroup' ], "$script destroy xxxTestGroup " );

