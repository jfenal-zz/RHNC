use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'RHNC',
    license             => 'perl',
    dist_author         => 'Jérôme Fenal <jfenal@redhat.com>',
    dist_version_from   => 'lib/RHNC.pm',
    build_requires => {
        'Test::More' => 0,
        'Params::Validate' => 0,
        'Frontier::Client' => 0,
    },
    add_to_cleanup      => [ 'RHNC-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
