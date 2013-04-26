#!/usr/bin/env perl

use inc::Module::Install 1.02;

name 'AsyncExample';
all_from 'lib/AsyncExample.pm';

requires 'AnyEvent';
requires 'Twiggy';
requires 'IO::Async';
requires 'Net::Async::HTTP::Server';
requires 'Catalyst::Runtime' => '5.90030';
requires 'Moose';
test_requires 'Test::More' => '0.88';

auto_install;
WriteAll;
