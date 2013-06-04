package AsyncExample::Controller::AnyEvent::Timer;

use Moose;
use MooseX::MethodAttributes;
use AnyEvent;

extends 'Catalyst::Controller';

sub start : ChainedParent
 PathPart('') CaptureArgs(0) { }

sub timer : Chained('start') Args(0) {
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

sub prepare_cb {
  my $write_fh = pop;
  return sub {
    my $message = shift;
    $write_fh->write("Finishing: $message\n");
    $write_fh->close;
  };
}

__PACKAGE__->meta->make_immutable;
