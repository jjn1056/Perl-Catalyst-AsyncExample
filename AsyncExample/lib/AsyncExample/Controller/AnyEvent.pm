package AsyncExample::Controller::AnyEvent;

use Moose;
use MooseX::MethodAttributes;
use AnyEvent::IO qw(:DEFAULT :flags);
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;
use Protocol::WebSocket::URL;

extends 'Catalyst::Controller';

sub prepare_cb {
  my $write_fh = pop;
  return sub {
    my $message = shift;
    $write_fh->write("Finishing: $message\n");
    $write_fh->close;
  };
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

sub echo :Local Args(0) {
  my ($self, $c) = @_;
  my $uri = $c->req->uri;
  $c->stash(websocket_url =>
    Protocol::WebSocket::URL->new(
      host=>$uri->host, port=>$uri->port, resource_name=>'/anyevent/wsecho'));

  $c->forward($c->view('HTML'));
}

sub wsecho :Local Args(0) {
  my ($self, $c) = @_;
  my $io = $c->req->io_fh;
  my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($c->req->env);
  my $hd = AnyEvent::Handle->new(fh => $io);

  $hs->parse($io);
  $hd->push_write($hs->to_string);
  $hd->push_write(Protocol::WebSocket::Frame->new("Echo Initiated")->to_bytes);

  $hd->on_read(sub {
    (my $frame = $hs->build_frame)->append($_[0]->rbuf);
    while (my $message = $frame->next) {
      $message = Protocol::WebSocket::Frame->new($message)->to_bytes;
      $hd->push_write($message);
    }
  });

}

__PACKAGE__->meta->make_immutable;

