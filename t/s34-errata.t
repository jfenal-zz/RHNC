#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  s34-errata.t
#
#  DESCRIPTION:  test rhnc-errata
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Jérôme Fenal
#      COMPANY:  Red Hat
#      VERSION:  1.0
#      CREATED:  09/10/2010
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Data::Dumper;
use lib qw( . lib lib/RHNC );
use Cwd qw( abs_path );

use Test::More;    # last test to print
my $script = 'rhnc-errata';

eval "use Test::Script::Run qw( :all )";
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

#BEGIN { $tests++; }
#run_not_ok( $s, [qw( )], "$script (no arg)" );
#
#BEGIN { $tests++; }
#run_ok( $s, [ qw( lac ) ], "$script lac");
#
#BEGIN { $tests++; }
#like( last_script_stdout(), qr{ noarch }msix, "$script lac mentions noarch" );
#BEGIN { $tests++; }
#like( last_script_stdout(), qr{ i386 }msix, "$script lac mentions i386" );
#
#BEGIN { $tests++; }
#run_ok( $s, [ qw( lac -u ) ], "$script lac -u");
#
#BEGIN { $tests++; }
#like( last_script_stdout(), qr{ noarch }msix, "$script lac mentions noarch" );
#BEGIN { $tests++; }
#like( last_script_stdout(), qr{ i386 }msix, "$script lac mentions i386" );
#
#BEGIN { $tests++; }
#run_ok( $s, [ qw( get 1 ) ], "$script get 1");
#
