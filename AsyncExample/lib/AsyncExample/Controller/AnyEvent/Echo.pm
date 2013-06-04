package AsyncExample::Controller::AnyEvent::Echo;

use Moose;
use MooseX::MethodAttributes;
use AnyEvent::IO qw(:DEFAULT :flags);
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;
use Protocol::WebSocket::URL;

extends 'Catalyst::Controller';

sub start : ChainedParent
 PathPart('echo') CaptureArgs(0) { }

  sub index :Chained('start') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $uri = $c->req->uri;
    $c->stash(websocket_url =>
      Protocol::WebSocket::URL->new(
        host=>$uri->host, port=>$uri->port,
          resource_name=>'/anyevent/echo/ws'));

    $c->forward($c->view('HTML'));
  }

  sub ws :Chained('start') Args(0) {
    my ($self, $c) = @_;
    my $io = $c->req->io_fh;
    my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($c->req->env);
    my $hd = AnyEvent::Handle->new(fh => $io);

    $hs->parse($io);
    $hd->push_write($hs->to_string);
    $hd->push_write($hs->build_frame(buffer => "Echo Initiated")->to_bytes);

    $hd->on_read(sub {
      (my $frame = $hs->build_frame)->append($_[0]->rbuf);
      while (my $message = $frame->next) {
        $message = $hs->build_frame(buffer => $message)->to_bytes;
        $hd->push_write($message);
      }
    });
  }

__PACKAGE__->meta->make_immutable;

