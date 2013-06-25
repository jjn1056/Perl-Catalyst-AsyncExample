package AsyncExample;

use Catalyst;

__PACKAGE__->config(
    name => 'AsyncExample',
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, 
);

__PACKAGE__->setup();

=head1 NAME

AsyncExample - Catalyst based application

=head1 SYNOPSIS

    script/asyncexample_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<AsyncExample::Controller::Root>, L<Catalyst>

=head1 AUTHOR

john napiorkowski

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


