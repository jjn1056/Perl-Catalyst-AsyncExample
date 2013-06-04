package AsyncExample::Controller::AnyEvent::Chat;

use Moose;
use MooseX::MethodAttributes;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;
use Protocol::WebSocket::URL;
use JSON;

extends 'Catalyst::Controller';

has 'history' => (
  is => 'bare',
  traits => ['Array'],
  isa  => 'ArrayRef[HashRef]',
  default => sub { +[] },
  handles => {
    history => 'elements',
    add_to_history => 'push'});

has 'clients' => (
  is => 'bare',
  traits => ['Array'],
  default => sub { +[] },
  handles => {
    clients => 'elements',
    add_client => 'push'});

sub start : ChainedParent
 PathPart('chat') CaptureArgs(0) { }

  sub index : Chained('start') PathPart('') GET Args(0)
  {
    my ($self, $ctx) = @_;
    my $uri = $ctx->req->uri;
    $ctx->stash(
      websocket_url => Protocol::WebSocket::URL->new(
        host=>$uri->host, port=>$uri->port,
          resource_name => '/anyevent/chat/ws'));

    $ctx->forward($ctx->view('HTML'));
  }

  sub ws : Chained('start') Args(0)
  {
    my ($self, $ctx) = @_;
    my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($ctx->req->env);
    my $hd = AnyEvent::Handle->new(fh => (my $io = $ctx->req->io_fh));

    $self->add_client($hd);
    $hs->parse($io);
    $hd->push_write($hs->to_string);

    $hd->on_read(sub {
      (my $frame = $hs->build_frame)->append($_[0]->rbuf);
      while (my $message = $frame->next) {
        my $decoded = decode_json $message;
        if(my $user = $decoded->{new}) {
          $decoded = {username=>$user, message=>"Joined!"};
          foreach my $item ($self->history) {
            $hd->push_write(
              $hs->build_frame(buffer=>encode_json($item))
                ->to_bytes);
          }            
        } 

        $self->add_to_history($decoded);
        foreach my $client($self->clients) {
          $client->push_write(
            $hs->build_frame(buffer=>encode_json($decoded))
              ->to_bytes);
        }
      }
    });
  }

__PACKAGE__->meta->make_immutable;
