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
use Cwd qw( abs_path ) ;

use Test::More;    # last test to print
my $script = 'rhnc-sg';

eval "use Test::Script::Run";
plan skip_all => "Test::Script::Run required for testing $script" if $@;

my $s;
for my $d ( qw( . script ../script ) ) {
    $s = "$d/$script" if -f "$d/$script";
}

$s = abs_path $s;

my $tests;
plan tests => $tests;

BEGIN { $tests++; }
ok( defined $s, "script to test found : $s");

my ( $rc, $stdout, $stderr );

BEGIN { $tests++; }
run_ok( $s, [ qw( list ) ], "$script list" );

