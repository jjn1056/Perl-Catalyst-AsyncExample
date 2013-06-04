package AsyncExample::Controller::AnyEvent;

use Moose;
use MooseX::MethodAttributes;
extends 'Catalyst::Controller';

sub start : Chained(/)
 PathPrefix CaptureArgs(0) { }

__PACKAGE__->meta->make_immutable;

