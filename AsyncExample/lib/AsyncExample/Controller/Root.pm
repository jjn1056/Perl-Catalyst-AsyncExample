package AsyncExample::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

AsyncExample::Controller::Root - Root Controller for AsyncExample

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
  my ($self, $c) = @_;

  my $res = $c->res;
  my $cb = sub {
    my $message = shift;
    $res->write("Finishing: $message\n");
    $res->write("DONE");
    $res->_writer->close;
  };

  my $watcher;
  $watcher = AnyEvent->timer(
    after => 5,
    cb => sub {
      $cb->(scalar localtime);
      undef $watcher; # cancel circular-ref
    });
}

=head1 AUTHOR

john napiorkowski

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
