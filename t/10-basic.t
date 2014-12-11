{
    package Failover;

    use Moo;

    has error => ( is => 'ro', );

}

{

    package Sub1;

    use Moo;
    use MooX::Types::MooseLike::Base qw/ Int Str /;

    use MooX::Failover;

    has num => (
        is  => 'ro',
        isa => Int,
    );

    has r_str => (
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    has d_str => (
        is       => 'ro',
        isa      => Str,
        required => 1,
        default  => 'wibble',
    );

    failover_to class => 'Failover';
}

{

    package Sub2;

    use Moo;
    extends 'Sub1';

    use MooX::Types::MooseLike::Base qw/ Str /;

    has q_str => (
        is       => 'ro',
        isa      => Str,
        required => 1,
        init_arg => 'str',
    );



}

use Test::Most;

{
    note "no errors";

    my $obj = Sub1->new(
        num   => 123,
        r_str => 'test',
    );

    isa_ok $obj, 'Sub1';
}

{
    note "no errors";

    my $obj = Sub2->new(
        num   => 123,
        r_str => 'test',
        str   => 'foo',
    );

    isa_ok $obj, 'Sub1';
    isa_ok $obj, 'Sub2';
}

{
    note "errors with no failover";

    my $obj = Sub1->new( num => 123, );
    isa_ok $obj, 'Failover';
    like $obj->error, qr/Missing required arguments: r_str/, 'expected error';

}

done_testing;
