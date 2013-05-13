package AsyncExample::Controller::Root;

use Moose;
use Carp::Always;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub prepare_cb {
  my $write_fh = pop;
  return sub {
    my $message = shift;
    $write_fh->write("Finishing: $message\n");
    $write_fh->close;
  };
}

sub ioasync :Local :Args(0) {
  my ($self, $c) = @_;
  my $cb = $self->prepare_cb($c->res->write_fh);

  $c->req->env->{'io.async.loop'}->watch_time(
    after => 5,
    code => sub { $cb->(scalar localtime) },
  );
}

sub anyevent :Local :Args(0) {
  my ($self, $c) = @_;
  my $cb = $self->prepare_cb($c->res->write_fh);

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
