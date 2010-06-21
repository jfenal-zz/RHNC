#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  s01-channel.t
#
#  DESCRIPTION:  test rhnc-channel
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Jérôme Fenal
#      COMPANY:  Red Hat
#      VERSION:  1.0
#      CREATED:  24/05/2010 15:02:59
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Data::Dumper;
use lib qw( . lib lib/RHNC );
use Cwd qw( abs_path );

use Test::More;    # last test to print
my $script = 'rhnc-channel';

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

my ( $return_code, $stdout, $stderr );

BEGIN { $tests++; }
run_ok( $s, [qw( )], "$script (no arg)" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) = run_script( $s, [qw( list )] );
ok( $return_code, "$script list" );
my @chan;
foreach my $c ( split( /\n/, $stdout ) ) {
    chomp $c;
    push @chan, $1 if $c =~ m{ \A ( [^\s]+ ) \z}imxs;
}

# take the last channel
my $testchan = $chan[-1];
chomp $testchan;
BEGIN { $tests++; }
run_ok( $s, [qw( list -a -v )], "$script list -a -v" );

BEGIN { $tests++; }
run_ok( $s, [qw( la )], "$script list_arches" );

BEGIN { $tests++; }
run_ok( $s, [qw( le )], "$script list_errata (no arg)" );

BEGIN { $tests++; }
run_ok( $s, [ 'le', $testchan ], "$script list_errata $testchan" );

BEGIN { $tests++; }
run_ok( $s, [ 'ls', $testchan ], "$script list_systems $testchan" );

BEGIN { $tests++; }
run_ok( $s, [ 'lp', $testchan ], "$script list_packages $testchan" );

BEGIN { $tests++; }
run_ok(
    $s,
    [ qw( lp -a -v), $testchan ],
    "$script list_packages -a -v $testchan"
);

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) =
  run_script( $s, [qw( destroy new-channel-i386 )], );
ok( $return_code != 0,
    "$script destroy non-existant channel new-channel-i386" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) = run_script( $s, [qw( create )], );
ok( $return_code != 0, "$script create (no arg)" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) =
  run_script( $s, [qw( create new-channel-x86_64 -a noarch )] );
ok( $return_code != 0,
    "$script create channel with non-existant channel arch" );

BEGIN { $tests++; }
run_ok(
    $s,
    [
        'create', 'new-channel-i386', '-n', 'new-channel-i386',
        '-s',     'new-channel-i386', '-a', 'channel-ia32'
    ],
    "$script create new-channel-i386"
);

BEGIN { $tests++; }
run_ok(
    $s,
    [
        'create', 'new-channel-x86_64', '-a', 'x86_64', '-p', 'new-channel-i386'
    ],
    "$script create new-channel-x86_64"
);

BEGIN { $tests++; }
run_ok( $s, [qw( get new-channel-i386)], "$script get new-channel-i386" );

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'destroy', 'new-channel-x86_64' ],
    "$script destroy new-channel-x86_64"
);

BEGIN { $tests++; }
run_ok(
    $s,
    [ 'destroy', 'new-channel-i386' ],
    "$script destroy new-channel-i386"
);

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) =
  run_script( $s, [qw( create new-channel-i386 -x new-channel-i386 )], );
is( $return_code, 1, "$script create (wrong parms)" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) = run_script( $s, [qw( destroy )], );
ok( $return_code != 0, "$script destroy (no arg)" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) =
  run_script( $s, [qw( destroy such-a-random-channel-name )], );
ok( $return_code != 0, "$script destroy non-existant channel" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) =
  run_script( $s, [qw( get such-a-random-channel-name )], );
ok( $return_code != 0, "$script get non-existant channel" );

BEGIN { $tests++; }
( $return_code, $stdout, $stderr ) =
  run_script( $s, [qw( such_a_random_command )], );
ok( $return_code != 0, "$script unknown command" );

