package AsyncExample::Controller::AnyEvent::Stream;

use Moose;
use MooseX::MethodAttributes;
use AnyEvent::IO qw(:DEFAULT :flags);

extends 'Catalyst::Controller';

sub start : ChainedParent
 PathPart('') CaptureArgs(0) { }

sub stream :Chained('start') Args(0) {
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

sub read_chunk {
  my ($self, $fh, $wfh) = @_;
  aio_read $fh, 4096, sub {
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

__PACKAGE__->meta->make_immutable;
