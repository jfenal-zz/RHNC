#!perl

use strict;
use warnings;
use File::Find;

our @modules;
my $tests = 0;
use Test::More;

BEGIN {
    find(
        sub {
            push @modules, $File::Find::name
              if $File::Find::name =~ m/.*\.pm$/
                  && $File::Find::name !~ m/Template\.pm$/;
        },
        qw( lib )
    );

    $tests = scalar @modules;
}

sub not_in_file_ok {
    my ( $filename, %regex ) = @_;
    open( my $fh, '<', $filename )
      or die "couldn't open $filename for reading: $!";

    my %violated;

    while ( my $line = <$fh> ) {
        while ( my ( $desc, $regex ) = each %regex ) {
            if ( $line =~ $regex ) {
                push @{ $violated{$desc} ||= [] }, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    }
    else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok(
        $module => 'the great new $MODULENAME' => qr/ - The great new /,
        'boilerplate description'  => qr/Quick summary of what the module/,
        'stub function definition' => qr/function[12]/,
        "template" => qr/This package is just a template for future modules/,
    );
}

TODO: {

    #    local $TODO = "Need to replace the boilerplate text";

    not_in_file_ok(
        README => "The README is used..." => qr/The README is used/,
        "'version information here'" => qr/to provide version information/,
        "'report any bugs'"          => qr/bug-rhn-session at rt.cpan.org/,
    );

    not_in_file_ok( Changes => "placeholder date/time" => qr(Date/time) );

    foreach my $pm (@modules) {
        module_boilerplate_ok $pm;

    }
}
done_testing( 2 + scalar @modules );
