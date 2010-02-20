use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'RHNC::Session',
    license             => 'perl',
    dist_author         => 'Jérôme Fenal <jfenal@redhat.com>',
    dist_version_from   => 'lib/RHNC/Session.pm',
    build_requires => {
        'Test::More' => 0,
        'Params::Validate' => 0,
        'Frontier::Client' => 0,
    },
    add_to_cleanup      => [ 'RHNC-Session-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
