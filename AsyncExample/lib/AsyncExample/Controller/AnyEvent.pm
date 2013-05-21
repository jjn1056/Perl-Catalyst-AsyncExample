package AsyncExample::Controller::AnyEvent;

use Moose;
use MooseX::MethodAttributes;
use AnyEvent::IO qw(:DEFAULT :flags);
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

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
  $c->forward($c->view('HTML'));
}

sub wsecho :Local Args(0) {
  my ($self, $c) = @_;
  my $io = (my $env = $c->req->env)->{'psgix.io'};
  my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($env);
  my $hd; $hd = AnyEvent::Handle->new(
    fh => $io,
    on_eof => sub { warn "EOF" },
    on_error => sub {
      my ($hdl, $fatal, $msg) = @_;
      AE::log error => $msg;
      $hdl->destroy;
    },
  );

  $hs->parse($io) || die "Error: ${\$hs->error}";
  $hd->push_write($hs->to_string);
  $hd->push_write(Protocol::WebSocket::Frame->new("ROCKS")->to_bytes);

  $hd->on_read(sub {
    (my $frame = $hs->build_frame)->append($_[0]->rbuf);
    while (my $message = $frame->next) {
      $message = Protocol::WebSocket::Frame->new($message)->to_bytes;
      $hd->push_write($message);
    }
  });

}

__PACKAGE__->meta->make_immutable;


__END__


  my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($c->req->env);



  





  my $h; $h = 



  my $frame = Protocol::WebSocket::Frame->new;

  $h->push_write($hs->to_string);

  $h->on_eof(sub { warn "DONE" });
  $h->on_read(
    sub {
      warn "on read...";
      $frame->append($_[0]->rbuf);
      while (my $message = $frame->next) {
        $h->push_write(Protocol::WebSocket::Frame->new($message)->to_bytes);
      }
    });


sub wsecho :Local Args(0) {
  my ($self, $c) = @_;
  my $wfh = $c->res->write_fh;
  my $fh = $c->req->env->{'psgix.io'} || die "no io $!";
  my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($c->req->env);
  my $frame = Protocol::WebSocket::Frame->new;

  $hs->parse($fh) || die "Error: ${\$hs->error}";

  my $h = AnyEvent::Handle->new(
    fh => $fh,
    on_oef => sub { warn "DONE" },
    on_error => sub {
      my ($hdl, $fatal, $msg) = @_;
      AE::log error => $msg;
      $hdl->destroy;
    },
    on_read => sub {
      warn "on read...";
      my ($hdl, $fatal, $msg) = @_;
      $frame->append($hdl->rbuf);
      while (my $message = $frame->next) {
        $hdl->push_write(Protocol::WebSocket::Frame->new($message)->to_bytes);
      };
    }
  );

  $h->push_write($hs->to_string);
}

