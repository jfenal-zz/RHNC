use strict;
use warnings;
use Test::More;
use File::Find;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
my $r1 = eval( "use Test::Pod::Coverage $min_tpc" );
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $r1;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
my $r2 = eval( "use Pod::Coverage $min_pc" );
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $r2;

my @scripts;

find( \&wanted, 'script/');

sub wanted {
    if ($File::Find::name =~ m! script / rhnc - !imxs) {
        push @scripts, $File::Find::name;
    }
}

plan tests => scalar @scripts;

foreach my $s (@scripts) {
    pod_coverage_ok($s);
}
