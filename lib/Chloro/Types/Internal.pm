package Chloro::Types::Internal;
BEGIN {
  $Chloro::Types::Internal::VERSION = '0.04';
}

use strict;
use warnings;

use MooseX::Types -declare => [
    qw(
        Result
        )
];

role_type Result, { role => 'Chloro::Role::Result' };

1;
