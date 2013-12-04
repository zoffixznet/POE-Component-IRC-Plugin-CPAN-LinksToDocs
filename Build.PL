use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'POE::Component::IRC::Plugin::CPAN::LinksToDocs',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/POE/Component/IRC/Plugin/CPAN/LinksToDocs.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'POE::Component::IRC::Plugin::BaseWrap' => 0.001,
        'CPAN::LinksToDocs'                     => 0.001,
    },
    add_to_cleanup      => [ 'POE-Component-IRC-Plugin-CPAN-LinksToDocs-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
