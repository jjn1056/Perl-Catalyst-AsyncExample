package AsyncExample::Controller::Root;

use Moose;
use MooseX::MethodAttributes;

extends 'Catalyst::Controller';

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

__PACKAGE__->meta->make_immutable;

