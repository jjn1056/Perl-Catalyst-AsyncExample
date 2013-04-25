use strict;
use warnings;

# use AnyEvent;
use AsyncExample;

my $app = AsyncExample->apply_default_middlewares(AsyncExample->psgi_app);
$app;

