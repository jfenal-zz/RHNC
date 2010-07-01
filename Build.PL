use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'RHNC',
    license           => 'perl',
    dist_author       => 'Jérôme Fenal <jfenal@redhat.com>',
    dist_version_from => 'lib/RHNC.pm',
    requires          => {
        'Getopt::Long'     => 2.37,
        'Frontier::Client' => 0,
        'Params::Validate' => 0,
        'Config::IniFiles' => 0,
        'IO::Socket::SSL'  => 0,

    },
    build_requires => { 'Test::More' => 0, },
    recommends     => {
        'Test::Script::Run'   => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Script::Run'   => 0,
        'Devel::Cover'        => 0,
        'Perl::Critic'        => 0,
        'Perl::Tidy'          => 0,
    },
    add_to_cleanup     => ['RHNC-*'],
    create_makefile_pl => 'traditional',

    #    sign               => 1,
);

$builder->create_build_script();
