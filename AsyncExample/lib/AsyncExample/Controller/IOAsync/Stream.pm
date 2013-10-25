package AsyncExample::Controller::IOAsync::Stream;

use Moose;
use MooseX::MethodAttributes;
use IO::AIO;

extends 'Catalyst::Controller';

sub start : ChainedParent
 PathPart('') CaptureArgs(0) { }

sub stream :Chained('start') Args(0) {
  my ($self, $c) = @_;
  my $wfh = $c->res->write_fh;
  my $loop = $c->req->env->{'io.async.loop'};
  my $path = $c->path_to('root','file.png');
  $c->res->content_type('image/png');

  aio_open "$path", O_RDONLY, 0, sub {
    my ($fh) = @_ or
      die "$path: $!";
    $self->read_chunk($fh, $wfh);
  }
}

sub read_chunk {
  my ($self, $fh, $wfh) = @_;
  aio_read $fh, 4096, sub {
    my ($data) = @_ or
      die "read from fh: $!";
    if(length $data) {
      $wfh->write($data);
      $self->read_chunk($fh, $wfh);
    } else {
      $wfh->close;
      aio_close $fh, sub { };
    }
  }
}

__PACKAGE__->meta->make_immutable;
