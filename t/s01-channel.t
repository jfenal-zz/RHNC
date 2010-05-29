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
use lib qw( . lib lib/RHNC );

use Test::More;    # last test to print
my $script = 'rhnc-channel';

eval "use Test::Script";
plan skip_all => "Test::Script::Run required for testing $script" if $@;

my $s;
for my $d ( qw( . script ../script ) ) {
    $s = "$d/$script" if -f "$d/$script";
}

my $tests;
plan tests => $tests;

BEGIN { $tests++; }
ok( defined $s, "script to test found : $s");

BEGIN { $tests++; }
script_compiles( $s, "$s compiles" );

=pod
my ( $return, $stdout, $stderr );

BEGIN { $tests++; }
( $return, $stdout, $stderr ) = run_script( $s, [ 'list' ] );
is( $return, 0, "rcode : $return" );

=cut
