#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  s20-activationkey.t
#
#  DESCRIPTION:  test rhnc-ak
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

use Test::More;    # last test to print
my $script = 'rhnc-ak';

eval "use Test::Script::Run";
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
run_ok( $s, [qw( )], "$script (no arg)" );

BEGIN { $tests++; }
( $rc, $stdout, $stderr ) = run_script( $s, [qw( help )] );
is( $rc, 1, "$script help exits with 1" );

BEGIN { $tests++; }
run_ok( $s, [qw( list )], "$script list" );

BEGIN { $tests++; }
run_ok( $s, [qw( list -r)], "$script list -r" );

BEGIN { $tests++; }
run_ok( $s, [qw( list -v)], "$script list -v" );

BEGIN { $tests++; }
run_ok( $s, [qw( wrong command)], "$script wrong command" );

my $newak;

BEGIN { $tests++; }
( $rc, $stdout, $stderr ) =
  run_script( $s, [qw( create -e v,m,p -d new-test-key -l 20 )], );
chomp $stdout;
$newak = $1 if $stdout =~ m/ : \s* (.*) \z/imxs;
ok( $rc, "$script create (no name)" );
BEGIN { $tests++; }
ok( $newak, "we have a name : <$newak>" );

BEGIN { $tests++; }
run_ok( $s, [ 'get', $newak ], "$script get $newak" );

BEGIN { $tests++; }
run_ok( $s, [ 'destroy', $newak ], "$script destroy $newak" );

BEGIN { $tests++; }
( $rc, $stdout, $stderr ) = run_script(
    $s,
    [
        qw( create -n test-key -e v,m,p -u -d ),
        'new test key2',
        qw( -l 20 -b rhel-i386-server-5)
    ],
);
chomp $stdout;
undef $newak;
$newak = $1 if $stdout =~ m/ : \s* (.*) \z/imxs;
ok( $rc, "$script create -n test-key" );

BEGIN { $tests++; }
ok( $newak, "we have a name : <$newak>" );

BEGIN { $tests++; }
run_ok( $s, [ 'get', $newak ], "$script get $newak" );

BEGIN { $tests++; }
run_ok( $s, [ 'destroy', $newak ], "$script destroy $newak" );

BEGIN { $tests++; }
( $rc, $stdout, $stderr )=
run_script( $s, [ 'destroy', 'such-a-random-key-name' ]);
ok($rc != 0, "$script destroy non-existant key" );
