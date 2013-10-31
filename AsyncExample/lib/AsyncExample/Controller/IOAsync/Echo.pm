package AsyncExample::Controller::IOAsync::Echo;

use base 'Catalyst::Controller';
use Protocol::WebSocket::Handshake::Server;
use Net::Async::WebSocket::Server;

sub start : ChainedParent
 PathPart('echo') CaptureArgs(0) { }

  sub index :Chained('start') PathPart('') Args(0)
  {
    my ($self, $c) = @_;
    my $url = $c->uri_for_action($self->action_for('ws2'));
    
    $url->scheme('ws');
    $c->stash(websocket_url => $url);
    $c->forward($c->view('HTML'));
  }

  sub ws2 :Chained('start') Args(0)
  {
    my ($self, $c) = @_;
    my $io = $c->req->io_fh;
    my $server = Net::Async::WebSocket::Server->new(
      on_client => sub {
        my ( $self, $client ) = @_;
        $self->send_frame( 'Echo Initiated' );
        $client->configure(
          on_frame => sub {
            my ( $self, $frame ) = @_;
            $self->send_frame( $frame );
          },
        );
      }
    );

    $c->req->env->{'io.async.loop'}->add($server);
    $server->listen(handle=>$io);
  }

  sub ws :Chained('start') Args(0)
  {
    my ($self, $c) = @_;
    my $io = $c->req->io_fh;
    my $hs = Protocol::WebSocket::Handshake::Server
      ->new_from_psgi($c->req->env);

    $io->configure(
      on_read => sub {
        my ($stream, $buff, $oef) = @_;
        if($hs->is_done) {
          (my $frame = $hs->build_frame)->append($$buff);
          while (my $message = $frame->next) {
            $message = $hs->build_frame(buffer => $message)->to_bytes;
            $stream->write($message);
          }
          return 0;
        } else {
          $hs->parse($$buff);
          $stream->write($hs->to_string);
          $stream->write($hs->build_frame(buffer => "Echo Initiated")->to_bytes); 
        }
      }
    );
  }

1;
