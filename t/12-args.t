{
    package Failover2;

    use Moo;
    use Types::Standard qw/ Str /;

    has 'error2' => ( is => 'ro' );
    has 'class2' => ( is => 'ro', isa => Str );

    our $count = 0;

    sub alt_new {
      ++$count;
      shift->new(@_);
    }
}

{

    package Sub1;

    use Moo;
    use Types::Standard qw/ Int Str /;

    use MooX::Failover;
    use lib 't/lib';

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

    failover_to 'Failover2' => ( err_arg => 'error2', class_arg => 'class2', constructor => 'alt_new' );
}

{

    package Sub2;

    use Moo;
    use Types::Standard qw/ Int Str /;

    use MooX::Failover;
    use lib 't/lib';

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

    failover_to 'Failover2' => ( err_arg => undef, class_arg => undef );
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
    note "errors with failover";

    my $obj = Sub1->new( num => 123, );
    isa_ok $obj, 'Failover2';
    is $Failover2::count, 1, 'alternative constructor run';
    like $obj->error2, qr/Missing required arguments: r_str/, 'expected error';
    is $obj->class2, 'Sub1', 'expected class';
}

{
    note "errors with failover using alternative constructor";

    my $obj = Sub1->new( num => 123, );
    isa_ok $obj, 'Failover2';
    like $obj->error2, qr/Missing required arguments: r_str/, 'expected error';
    is $obj->class2, 'Sub1', 'expected class';
}


{
    note "errors with failover but no err/class args";

    my $obj = Sub2->new( num => 123, );
    isa_ok $obj, 'Failover2';
    is $obj->error2, undef, 'no error arg';
    is $obj->class2, undef, 'no class arg';
}

done_testing;
