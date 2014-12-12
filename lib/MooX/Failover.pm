package MooX::Failover;

require Moo;

use Carp;
use Class::Load qw/ try_load_class /;
use Sub::Defer qw/ undefer_sub /;
use Sub::Quote qw/ quote_sub /;

{
    use version 0.77;
    $MooX::Failover::VERSION = version->declare('v0.2.0_01');
}

# RECOMMEND PREREQ: Class::Load::XS

=head1 NAME

MooX::Failover - Instantiate Moo classes with failover

=for readme plugin version

=head1 SYNOPSIS

  # In your class:

  package MyClass;

  use Moo;
  use MooX::Failover;

  has 'attr' => ( ... );

  # after attributes are defined:

  failover_to 'OtherClass';

  ...

  # When using the class

  my $obj = MyClass->new( %args );

  # If %args contains missing or invalid values or new otherwise
  # fails, then $obj will be of type "OtherClass".

=begin :readme

=head1 INSTALLATION

See
L<How to install CPAN modules|http://www.cpan.org/modules/INSTALL.html>.

=for readme plugin requires heading-level=2 title="Required Modules"

=for readme plugin changes

=end :readme

=head1 DESCRIPTION

This role provides constructor failover for L<Moo> classes.

If a class cannot be instantiated because of invalid arguments
(perhaps from an untrusted source), then instead it returns the
failover class (passing the same arguments to that class).

It is roughly equivalent to using

  my $obj = eval { MyClass->new(%args) //
     OtherClass->new( %args, error => $@ );

This allows for cleaner design, by not forcing you to duplicate type
checking for class parameters.

A use case for this module is for instantiating
L<Web::Machine::Resource> objects, where a resource class's attributes
correspond to URL arguments.  A type failure would normally cause an
internal serror error (HTTP 500).  Using L<MooX::Failover>, we can
return a different resource object that examines the error, and
returns a more appropriate error code, e.g. bad request (HTTP 400).

=for readme stop

Your failover class should support the same methods as the original
class, so that it (roughly) satisfies the Liskov Substitution
Principle, where all provable properties of the original class are
also provable of the failover class.  In practice, we only care about
the properties (methods and attributes) that are actually used in our
programs.

=head1 EXPORTS

The following function is always exported:

=head2 C<failover_to>

  failover_to $class => %options;

This specifies the class to instantiate if the constructor dies.

It should be specified I<after> all of the attributes have been
declared.

The following options are supported.

=over

=item C<class>

The name of the class to fail over to.  It defaults to C<$class>.

=item C<constructor>

The name of the constructor method. It defaults to "new".

=item C<args>

The arguments to pass to the failover class. When omitted, it will
pass the same arguments as the original class.

This can be a scalar (single argument), hash reference or array
reference.

=item C<err_arg>

This is the name of the constructor argument to pass the error to (it
defaults to "error".  This is useful if the failover class can inspect
the error and act appropriately.

For example, if the original class is a handler for a website, where
the attributes correspond to URL parameters, then the failover class
can return HTTP 400 responses if the errors are for invalid
parameters.

To disable it, set it to C<undef>.

=item C<class_arg>

This is the name of the constructor argument to pass the name class
that failed.  It defaults to "class".

To disable it, set it to C<undef>.

=back

This was originally a L<Moo> port of L<MooseX::Failover>.  The
interface was redesigned significantly, to be more efficient.

=head1 ATTRIBUTES

None. Since v0.2.0, there is no longer a C<failover_to> attribute.

=cut

sub import {
    my $caller = caller;
    my $name   = 'failover_to';
    my $code   = \&failover_to;
    my $this   = __PACKAGE__ . "::${name}";
    my $that   = "${caller}::${name}";
    $Moo::MAKERS{$caller}{exports}{$name} = $code;
    Moo::_install_coderef( $that, $this => $code );
}

sub unimport {
    my $caller = caller;
    Moo::_unimport_coderefs( $caller,
        { exports => { 'failover_to' => \&failover_to } } );
}

sub _ref_to_list {
    my ($next) = @_;

    my $args = $next{args} // ['@_'];
    if ( my $ref = ref $args ) {

        return ( @{$args} ) if $ref eq 'ARRAY';
        return ( %{$args} ) if $ref eq 'HASH';

        croak "args must be an ArrayRef, HashRef or Str";

    }
    else {

        return ($args);

    }

}

sub failover_to {
    my $class = shift;
    my %next  = @_;

    $next{class} //= $class;

    $next{class} or croak "no class defined";

    try_load_class( $next{class} )
      or croak "unable to load " . $next{class};

    my $caller = caller;

    $next{constructor} //= 'new';

    croak $next{class} . ' cannot ' . $next{constructor}
      unless $next{class}->can( $next{constructor} );

    $next{err_arg}   //= 'error' unless exists $next{err_arg};
    $next{class_arg} //= 'class' unless exists $next{class_arg};

    my $name = "${caller}::new";
    my $orig = undefer_sub \&{$name};

    my @args = _ref_to_list($next);
    push @args, $next{err_arg} . ' => $@' if defined $next{err_arg};
    push @args, $next{class_arg} . " => '${caller}'"
      if defined $next{class_arg};

    my $code_str =
        'my $class = shift; eval { $class->$orig(@_); }' . ' // '
      . $next{class} . '->'
      . $next{constructor} . '('
      . join( ',', @args ) . ')';

    quote_sub $name, $code_str, { '$orig' => \$orig, };
}

=for readme continue

=head1 SEE ALSO

L<MooseX::Failover>

=head1 AUTHOR

Robert Rothenberg C<<rrwo@thermeon.com>>

=head1 Acknowledgements

=over

=item Thermeon Europe.

=item Piers Cawley.

=back

=head1 COPYRIGHT

Copyright 2014 Thermeon Europe.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
