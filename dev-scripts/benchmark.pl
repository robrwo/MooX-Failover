
{

    package A;
    use Moo;
    use MooX::Types::MooseLike::Base qw/ Int /;

    has i => ( is => 'ro', isa => Int );
}

{

    package C;
    use Moo;
    use MooX::Types::MooseLike::Base qw/ Int /;
    use MooX::Failover;

    has i => ( is => 'ro', isa => Int );

    failover_to 'D';
}

{

    package D;
    use Moo;
    use MooX::Types::MooseLike::Base qw/ Str /;
    has i => ( is => 'ro', isa => Str );
}

use strict;
use warnings;

use Benchmark qw/ cmpthese /;
use Try::Tiny;

sub failover {
    C->new( i => 'x');
}

sub try_catch {
    try { A->new( i => 'x' ) } catch { D->new( i => 'x' ) };
}

sub eval_block {
    eval { A->new( i => 'x' ) } // D->new( i => 'x' );
}

sub failover_ok {
    C->new( i => '1' );
}

sub try_catch_ok {
    try { A->new( i => '1' ) } catch { D->new( i => '1' ) };
}

sub eval_block_ok {
    eval { A->new( i => '1' ) } // D->new( i => '1' );
}

cmpthese(
    10_000,
    {
        failover   => 'failover',
        try_catch  => 'try_catch',
        eval_block => 'eval_block',
    }
);

cmpthese(
    100_000,
    {
        failover   => 'failover_ok',
        try_catch  => 'try_catch_ok',
        eval_block => 'eval_block_ok',
    }
);

