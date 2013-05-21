package AsyncExample::View::HTML;

use strict;
use warnings;
use base 'Catalyst::View::TT';

sub log_dump {
  my ($self, $ctx, @args) = @_;
  use Devel::Dwarn;
  Dwarn \@args;
}

sub uri_for {
  my ($self, $ctx, @args) = @_;
  $ctx->uri_for(@args);
}

sub uri_for_action {
  my ($self, $ctx, @args) = @_;
  $ctx->uri_for_action(@args);
}

sub static {
  my ($self, $ctx, @args) = @_;
  $ctx->uri_for('/static', @args);
}

sub model {
  my ($self, $ctx, @args) = @_;
  $ctx->model(@args);
}

sub controller {
  my ($self, $ctx, @args) = @_;
  $ctx->controller(@args);
}

__PACKAGE__->config(
  expose_methods => [qw/
    uri_for_action model uri_for static
    controller log_dump /],
);
