package AsyncExample::Controller::IOAsync::Echo;

use Moose;
use MooseX::MethodAttributes;
use Protocol::WebSocket::Handshake::Server;

extends 'Catalyst::Controller';

sub start : ChainedParent
 PathPart('echo') CaptureArgs(0) { }

  sub index :Chained('start') PathPart('') Args(0)
  {
    my ($self, $c) = @_;
    my $url = $c->uri_for_action($self->action_for('ws'));
    
    $url->scheme('ws');
    $c->stash(websocket_url => $url);
    $c->forward($c->view('HTML'));
  }

  sub ws :Chained('start') Args(0)
  {
    my ($self, $c) = @_;
    my $io = $c->req->io_fh;
    my $hs = Protocol::WebSocket::Handshake::Server
      ->new_from_psgi($c->req->env);

    $hs->parse($io);

    $c->req->env->{'io.async.loop'}; ## ???

  }

__PACKAGE__->meta->make_immutable;

