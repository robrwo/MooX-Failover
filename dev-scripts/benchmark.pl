
{

    package A;
    use Moo;
    use MooX::Types::MooseLike::Base 'Int';

    has i => ( is => 'ro', isa => Int );
}

{

    package C;
    use Moo;
    use MooX::Types::MooseLike::Base 'Int';

    has i => ( is => 'ro', isa => Int );

    with 'MooX::Failover';
}

{

    package D;
    use Moo;

    # use MooX::Types::MooseLike::Base 'Str';
    # has i => ( is => 'ro', isa => Str );
}

use Benchmark qw/ cmpthese /;
use Try::Tiny;

use common::sense;

sub simple {
    C->new( i => 'x', failover_to => 'D' );
}

sub exception_try {
    try { A->new( i => 'x' ) } catch { D->new() };
}

sub exception_eval {
    eval { A->new( i => 'x' ) } // D->new();
}

sub simple_pass {
    C->new( i => '1', failover_to => 'D' );
}

sub no_exception {
    try { A->new( i => '1' ) } catch { D->new() };
}

cmpthese(
    10_000,
    {
        failover => 'simple',
        try      => 'exception_try',
        eval     => 'exception_eval',
    }
);

cmpthese(
    30_000,
    {
        no_failover => 'simple_pass',
        no_error    => 'no_exception',
    }
);

