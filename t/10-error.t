use Test::Most;

use MooX::Failover;

throws_ok {
  failover_to;
} qr/no class defined/, 'failover with no class';

throws_ok {
  failover_to 'InvalidModuleName';
} qr/unable to load InvalidModuleName/, 'failover with no class';


done_testing;

