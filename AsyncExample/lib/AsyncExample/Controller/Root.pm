package AsyncExample::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub ioasync :Local :Args(0) {
  my ($self, $c) = @_;

  my $res = $c->res;
  my $cb = sub {
    my $message = shift;
    $res->write("Finishing: $message\n");
    $res->_writer->close;
  };

  $c->req->env->{'io.async.loop'}->watch_time(
    after => 5,
    code => sub { $cb->(scalar localtime) },
  );
}

sub anyevent :Local :Args(0) {
  my ($self, $c) = @_;

  my $res = $c->res;
  my $cb = sub {
    my $message = shift;
    $res->write("Finishing: $message\n");
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
