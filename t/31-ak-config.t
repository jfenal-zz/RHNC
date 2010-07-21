#!/usr/bin/perl
use Test::More;
use strict;
use warnings;

use lib qw( . lib lib/RHNC );
use RHNC;
use Carp;
use Data::Dumper;

diag("Testing RHNC::ActivationKey $RHNC::ActivationKey::VERSION, Perl $], $^X");
my $tests;
plan tests => $tests;

my $rhnc = RHNC::Session->new();

my $ak;

# 1. create test AK
$ak = RHNC::ActivationKey::create(
    rhnc         => $rhnc,
    description  => "Test activation key",
    entitlements => [qw( provisioning_entitled )],   # necessary to add packages
);

# 2. get 2 config channels
my @ccl = @{ RHNC::ConfigChannel->list($rhnc) };

my $cc1 = $ccl[0];
my $cc2 = $ccl[-1];
croak "May I have at least 2 config channel for me to test, please ?"
  if $cc1->label eq $cc2->label;
my $cc1label = $cc1->label;
my $cc2label = $cc2->label;

my $cc_ref;
my %h;

# set 2 config channel
$ak->config_channels( set => [ $cc1->label, $cc2label ] );
$ak = $ak->get( $ak->name );
BEGIN { $tests++; }
is( scalar( @{ $cc_ref = $ak->config_channels } ),
    2, "Now 2 config channel in ak" . $ak->name );
diag( "config channels added : " . join ", ", @$cc_ref );
%h = map { $_ => 1 } @$cc_ref;
BEGIN { $tests++; }
ok( defined $h{$cc1label}, "$cc1label is here" );
BEGIN { $tests++; }
ok( defined $h{$cc2label}, "$cc2label is here" );



# remove 1 config channel
$ak->config_channels( remove => [ $cc1label ] );
$ak = $ak->get( $ak->name );

BEGIN { $tests++; }
is( scalar( @{ $cc_ref = $ak->config_channels } ),
    1, "Now config channel in ak" . $ak->name );
diag( "config channels in ak : " . join ", ", @$cc_ref );
%h = map { $_ => 1 } @$cc_ref;
BEGIN { $tests++; }
ok( !defined $h{$cc1label}, "$cc1label is not here" );
BEGIN { $tests++; }
ok( defined $h{$cc2label}, "$cc2label is here" );

$ak->config_channels( remove => [ $cc2label ] );
$ak = $ak->get( $ak->name );
BEGIN { $tests++; }
is( scalar( @{ $cc_ref = $ak->config_channels } ),
    0, "Now 0 config channel in ak" . $ak->name );


# re add 1st config channel
$ak->config_channels( add => [ $cc1->label, $cc2label ] );
$ak = $ak->get( $ak->name );
BEGIN { $tests++; }
is( scalar( @{ $ak->config_channels } ),
    2, "Now 2 config channel in ak" . $ak->name );
BEGIN { $tests++; }
is( scalar( @{ $cc_ref = $ak->config_channels } ),
    2, "Now 2 config channel in ak" . $ak->name );
diag( "config channels added : " . join ", ", @$cc_ref );
%h = map { $_ => 1 } @$cc_ref;
BEGIN { $tests++; }
ok( defined $h{$cc1label}, "$cc1label is here" );
BEGIN { $tests++; }
ok( defined $h{$cc2label}, "$cc2label is here" );

BEGIN { $tests++; }
ok( $ak->destroy, "destroy ok" );

