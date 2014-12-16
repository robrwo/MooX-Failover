use Test::Most;

use MooX::Failover;

throws_ok {
  failover_to;
} qr/no class defined/, 'failover with no class';

done_testing;

