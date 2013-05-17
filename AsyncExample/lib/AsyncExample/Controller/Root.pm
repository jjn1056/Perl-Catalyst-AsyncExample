package AsyncExample::Controller::Root;

use Moose;
use AnyEvent::IO qw(:DEFAULT :flags);

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

sub read_chunk {
  my ($self, $fh, $wfh) = @_;
  aio_read $fh, 1024, sub {
    my ($data) = @_ or
      return AE::log error => "read from fh: $!";
    if(length $data) {
      $wfh->write($data);
      $self->read_chunk($fh, $wfh);
    } else {
      $wfh->close;
      aio_close $fh, sub { };
    }
  }
}

sub stream :Local Args(0) {
  my ($self, $c) = @_;
  my $path = $c->path_to('root','file.png');
  $c->res->content_type('image/png');
  my $wfh = $c->res->write_fh;
  
  aio_open "$path", O_RDONLY, 0, sub {
    my ($fh) = @_ or
      return AE::log error => "$path: $!";
    $self->read_chunk($fh, $wfh);
  }
}

=head1 AUTHOR

john napiorkowski

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
