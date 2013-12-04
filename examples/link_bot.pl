use strict;
use warnings;

use lib '../lib';
use POE qw(Component::IRC  Component::IRC::Plugin::CPAN::LinksToDocs);

my $irc = POE::Component::IRC->spawn(
    nick        => 'DocBot',
    server      => 'irc.freenode.net',
    port        => 6667,
    ircname     => 'Documentation Bot',
);

POE::Session->create(
    package_states => [
        main => [ qw(_start irc_001 irc_cpan_links_to_docs) ],
    ],
);

$poe_kernel->run;

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'DocsPlug' =>
            POE::Component::IRC::Plugin::CPAN::LinksToDocs->new
    );

    $irc->yield( connect => {} );
}

sub irc_001 {
    $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
}

sub irc_cpan_links_to_docs {
    use Data::Dumper;
    print Dumper $_[ARG0];
}