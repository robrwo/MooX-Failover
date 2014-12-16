{
	package Sub1;

	use Moo;
	use Types::Standard qw/ Int /;

	has num => ( is => 'ro', isa => Int );

	our $count = 0;

	around 'new' => sub {
	  my $orig = shift;
	  my $class = shift;
	  ++$count;
	  $class->$orig(@_);
        };
}

{
	package Sub2;

	use Moo;
	use Types::Standard qw/ Int /;

	use MooX::Failover;
	use lib 't/lib';

	has num => ( is => 'ro', isa => Int );

	failover_to 'Sub1';
	failover_to 'Failover';
}

use Test::Most;

{
    note "errors with chained failover";

    my $obj = Sub2->new( num => 'x', );
    isa_ok $obj, 'Failover';
    is $obj->class, 'Sub2', 'expected class';
    is $Sub1::count, 1, 'tried Sub1';
}

done_testing;
