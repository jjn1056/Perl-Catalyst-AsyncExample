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
  my $path = $c->path_to('root','lorem.txt');
  $c->res->content_type('image/png');

  aio_open "$path", IO::AIO::O_RDONLY, 0, sub {
    my ($fh) = @_ or
      die "$path: $!";
    $self->read_chunk($fh, $wfh, 0);
  }
}

sub read_chunk {
  my ($self, $fh, $wfh, $offset) = @_;
  my $buffer = '';
  aio_read $fh, $offset, 4096, $buffer, 0, sub {
    my $status = shift;
    die "read error[$status]: $!" unless $status >= 0;
    if($status) {
      $wfh->write($buffer);
      #AsyncExample->log->warn('did a chunk');
      $self->read_chunk($fh, $wfh, ($offset + 4096) );
    } else {
      $wfh->close;
      aio_close $fh, sub { };
    }
  }
}

__PACKAGE__->meta->make_immutable;
