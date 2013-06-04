## Start like : CATALYST_DEBUG=1 plackup -Ilib asyncexample-anyevent.psgi

use strict;
use warnings;
use AnyEvent;
use AsyncExample;

my $app = AsyncExample->apply_default_middlewares(AsyncExample->psgi_app);
