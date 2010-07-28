#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  s31-activationkey.t
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
my @args;

eval "use Test::Script::Run qw( :all )";
plan skip_all => "Test::Script::Run required for testing $script" if $@;

my $s;
for my $d (qw( . script ../script )) {
    $s = "$d/$script" if -f "$d/$script";
}

$s = abs_path $s;

my $tests;
plan tests => $tests;

BEGIN { $tests++; }    # 1
ok( defined $s, "script to test found : $s" );

my ( $rc, $stdout, $stderr );

BEGIN { $tests++; }    # 2
run_not_ok( $s, [], "$script (no arg)" );

BEGIN { $tests++; }    # 3
run_not_ok( $s, [ get => '-z' ], "$script get (wrong option)" );

BEGIN { $tests++; }    # 4
run_not_ok( $s, [ list => '-z' ], "$script list (wrong option)" );

BEGIN { $tests++; }    # 5
run_not_ok( $s, [ create => '-z'], "$script create (wrong option)" );

BEGIN { $tests++; }    # 6
run_not_ok( $s, [ destroy => '-z'], "$script delete (wrong option)" );

BEGIN { $tests++; }    # 7
run_not_ok( $s, [ set => '-z'], "$script set (wrong option)" );

BEGIN { $tests++; }    # 8
run_not_ok( $s, [ add => '-z'], "$script add (wrong option)" );

BEGIN { $tests++; }    # 9
run_not_ok( $s, [ remove => '-z'], "$script remove (wrong option)" );

BEGIN { $tests++; }    # 10
( $rc, $stdout, $stderr ) = run_script( $s, [qw( help )] );
is( $rc, 1, "$script help exits with 1" );

BEGIN { $tests++; }    # 11
run_ok( $s, [qw( list )], "$script list" );

BEGIN { $tests++; }    # 12
run_ok( $s, [qw( list -r)], "$script list -r" );

BEGIN { $tests++; }    # 13
run_ok( $s, [qw( list -v)], "$script list -v" );

BEGIN { $tests++; }    # 14
run_not_ok( $s, [qw( wrong command)], "$script wrong command" );

my $newak;

BEGIN { $tests++; }    # 15
@args = (
    qw( create -v ),
    -e => 'v,m,p',
    -d => 'new-test-key',
    -l => '20',
);
run_ok( $s, \@args, "$script " . join( q( ), @args ) );
$stdout = last_script_stdout();
chomp $stdout;
$newak = $1 if $stdout =~ m/ : \s* (.*) \z/imxs;

BEGIN { $tests++; }    # 16
ok( $newak, "we have a name : <$newak>" );

BEGIN { $tests++; }    # 17
run_ok( $s, [ 'get', $newak ], "$script get $newak" );

BEGIN { $tests++; }    # 18
run_ok( $s, [ 'destroy', $newak ], "$script destroy $newak" );

BEGIN { $tests++; }    # 19
@args = (
    qw( create test-key -v),
    -u => '1',
    -d => 'new test key2',
    -e => 'p',
    -l => '20',
    -b => 'rhel-i386-server-5',
    -c => 'rhel-i386-server-cluster-storage-5,rhel-i386-server-cluster-5',
    -p => 'ricci,iscsi-initiator-utils,luci',
    -g => 'Clusters,RHEL5',
);
run_ok( $s, \@args, "$script " . join( q( ), @args ) );
$stdout = last_script_stdout();
undef $newak;
chomp $stdout;
$newak = $1 if $stdout =~ m/ : \s* (.*) \z/imxs or die "Cannot get
newak";

# should follow create
BEGIN { $tests++; }    # 20
ok( $newak, "we have a name : <$newak>" );

BEGIN { $tests++; }    # 21
@args = (
    'set',
    -e => q(,),
    -d => 'changed_description',
    -l => '10',
    -b => q(,),
    -c => q(n),
    -u => q(0)
);
run_ok( $s, \@args, "$script " . join( q( ), @args ) );

BEGIN { $tests++; }    # 22
@args = ( 'get', $newak );
run_ok( $s, \@args, "$script " . join( q( ), @args ) );

BEGIN { $tests++; }    # 23
@args = (
    'set',
    -d => 'new_description',
    -l => '20',
    -u => '1',
    $newak
);
run_ok( $s, \@args, "$script " . join( q( ), @args ) );

BEGIN { $tests++; }    # 24
@args = ( 'destroy', $newak );
run_ok( $s, \@args, "$script " . join( q( ), @args ) );

BEGIN { $tests++; }    # 25
@args = qw( destroy non-existant-key-name );
run_not_ok( $s, \@args, "$script " . join( q( ), @args ) );
