#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('POE::Component::IRC::Plugin::BaseWrap');
    use_ok('CPAN::LinksToDocs');
	use_ok( 'POE::Component::IRC::Plugin::CPAN::LinksToDocs' );
}

diag( "Testing POE::Component::IRC::Plugin::CPAN::LinksToDocs $POE::Component::IRC::Plugin::CPAN::LinksToDocs::VERSION, Perl $], $^X" );
