package POE::Component::IRC::Plugin::CPAN::LinksToDocs;

use strict;
use warnings;

our $VERSION = '0.001';

use base 'POE::Component::IRC::Plugin::BaseWrap';
use CPAN::LinksToDocs;

sub _make_default_args {
    return (
        trigger          => qr/^(?:ur[il]\s*(?:for)?|perldoc)\s+(?=\S+)/i,
        response_event   => 'irc_cpan_links_to_docs',
        linker           => CPAN::LinksToDocs->new
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;
    my $what = (split /,/, $in_ref->{what})[0];
    return [ join ' ', @{$self->{linker}->link_for($what)}];
}

sub _make_response_event {
    my ( $self, $in_ref ) = @_;
    $in_ref->{result} = $self->{linker}->link_for($in_ref->{what});
    return $in_ref;
}

1;
__END__

=head1 NAME

POE::Component::IRC::Plugin::CPAN::LinksToDocs - get links to http://search.cpan.org/ documentation from IRC

 =head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::CPAN::LinksToDocs);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'DocBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'CPAN LinksToDocs',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'LinksToDocs' =>
                POE::Component::IRC::Plugin::CPAN::LinksToDocs->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }

    <Zoffix> DocBot, uri Acme::BabyEater
    <DocBot> http://search.cpan.org/perldoc?Acme::BabyEater
    <Zoffix> DocBot, perldoc map
    <DocBot> http://perldoc.perl.org/functions/map.html
    <Zoffix> DocBot, perldoc RE
    <DocBot> http://search.cpan.org/perldoc?perlrequick
             http://search.cpan.org/perldoc?perlretut
             http://search.cpan.org/perldoc?perlre
             http://search.cpan.org/perldoc?perlreref

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
to link people to documentation on L<http://search.cpan.org> by giving
it predefined "tags" (see TAGS section in L<CPAN::LinksToDocs>)
or module names.
It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

The tags given to the plugin in IRC will be split on commas, only the
link(s) for the B<first> tag will be spoken in IRC B<but all> of the tags
will be processed and the B<all> the links will be returned in the response
event. See EMITED EVENTS section for more information.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        LinksToDocs => POE::Component::IRC::Plugin::CPAN::LinksToDocs->new
    );

    # juicy flavor
    $irc->plugin_add(
        LinksToDocs =>
            POE::Component::IRC::Plugin::CPAN::LinksToDocs->new(
                auto             => 1,
                response_event   => 'irc_docs_ready',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                trigger          => qr/^cpan\s+(?=\S)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                linker           => CPAN::LinksToDocs->new( tags => { m => 'http://m.com' } ),
                eat              => 1,
                debug            => 0,
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::CPAN::LinksToDocs> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. The possible
arguments/values are as follows:

=head3 auto

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emited by the plugin to retrieve the results (see
EMITED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 linker

    ->new(linker => CPAN::LinksToDocs->new(tags => { m => 'http://m.com/' } ));

B<Optional>. The C<linker> argument takes a L<CPAN::LinksToDocs> object as
a value, here's where you can add any custom tags if you want.
B<Defaults to:> standard, plain L<CPAN::LinksToDocs> object.

=head3 response_event

    ->new( response_event => 'event_name_to_recieve_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITED EVENTS
section for more information. B<Defaults to:> C<irc_cpan_links_to_docs>

=head3 banned

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 root

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 trigger

    ->new( trigger => qr/^cpan\s+(?=\S)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^(?:ur[il]\s*(?:for)?|perldoc)\s+(?=\S+)/i>

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^cpan\s+/>
you would make the request by saying C<Nick, cpan Acme::BabyEater>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 listen_for_input

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable functionality only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 eat

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 debug

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITED EVENTS

=head2 response_event

    $VAR1 = {
            'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
            'what' => 'map,grep,RE',
            'type' => 'public',
            'channel' => '#zofbot',
            'result' => [
                            'http://perldoc.perl.org/functions/map.html',
                            'http://perldoc.perl.org/functions/grep.html',
                            'http://search.cpan.org/perldoc?perlrequick',
                            'http://search.cpan.org/perldoc?perlretut',
                            'http://search.cpan.org/perldoc?perlre',
                            'http://search.cpan.org/perldoc?perlreref'
                        ],
            'message' => 'DocBot, perldoc map,grep,RE'
            };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_cpan_links_to_docs>) will recieve input
every time request is completed. The input will come in a form of a hashref.
The keys/values of that hashref are as follows:

=head2 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The usermask of the person who made the request.

=head2 what

    { 'what' => 'map,grep,RE' }

The user's message after stripping the trigger.

=head2 type

    { 'type' => 'public' }

The type of the request. This will be either C<public>, C<notice> or
C<privmsg>

=head2 channel

    { 'channel' => '#zofbot' }

The channel where the message came from (this will only make sense when the request came from a public channel as opposed to /notice or /msg)

=head2 message

    { 'message' => 'DocBot, perldoc map,grep,RE' }

The full message that the user has sent.

=head2 result

    {
        'result' => [
            'http://perldoc.perl.org/functions/map.html',
            'http://perldoc.perl.org/functions/grep.html',
            'http://search.cpan.org/perldoc?perlrequick',
            'http://search.cpan.org/perldoc?perlretut',
            'http://search.cpan.org/perldoc?perlre',
            'http://search.cpan.org/perldoc?perlreref'
        ],
    }

The result of the request. B<Note:> the "tags" given to the plugin will
be split on commas, only the link(s) for the B<first> tag of that split
will be spoken in IRC, B<but all> of them will be returned in the response
event.

=head1 SEE ALSO

L<CPAN::LinksToDocs>, L<POE::Component::IRC::Plugin>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-cpan-linkstodocs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-CPAN-LinksToDocs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::CPAN::LinksToDocs

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-CPAN-LinksToDocs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-CPAN-LinksToDocs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-CPAN-LinksToDocs>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-CPAN-LinksToDocs>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
