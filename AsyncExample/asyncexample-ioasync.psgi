## Start like CATALYST_DEBUG=1 plackup -Ilib -s Net::Async::HTTP::Server asyncexample-ioasync.psgi
use strict;
use warnings;

use AsyncExample;

my $app = AsyncExample->apply_default_middlewares(AsyncExample->psgi_app);
$app;

