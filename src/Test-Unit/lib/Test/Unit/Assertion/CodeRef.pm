package Test::Unit::Assertion::CodeRef;

use strict;
use base qw/Test::Unit::Assertion/;

use Carp;

my $deparser;

sub new {
    my $class       = shift;
    my $code = shift;
    croak "$class\::new needs a CODEREF" unless ref($code) eq 'CODE';
    bless \$code => $class;
}

sub do_assertion {
    my $self = shift;
    my $possible_object = $_[0];
    if (eval {$possible_object->isa('UNIVERSAL')}) {
        # It's an object!
        $possible_object->$$self(@_[1..$#_]) ||
            $self->fail("$possible_object\->{$self}(" .
                        join (", ", map {defined($_) ? $_ : '<undef>'} @_) .
                        ") failed" . ($@ ? " with error $@." : "."));
    }
    else {
        $$self->(@_) ||
            $self->fail("{$self}->(" . join(', ', map {defined($_) ? $_ : '<undef>'} @_) .
                        ") failed" . ($@ ? " with error $@." : "."));
    }
}

sub to_string {
    my $self = shift;
    if (eval "require B::Deparse") {
        $deparser ||= B::Deparse->new("-p");
        return join '', "sub ", $deparser->coderef2text($$self);
    }
    else {
        return "sub {
    # If you had a working B::Deparse, you'd know what was in
    # this subroutine.
}";
    }
}

1;
__END__

=head1 NAME

Test::Unit::Assertion::CodeRef - A delayed evaluation assertion using a Coderef

=head1 SYNOPSIS

    require Test::Unit::Assertion::CodeRef;

    my $assert_eq =
      Test::Unit::Assertion::CodeRef->new(sub {
        $_[0] eq $_[1] || die "Expected '$_[0]', got '$_[1]'\n"
      });

    $assert_eq->do_assertion('foo', 'bar');

Although this is how you'd use Test::Unit::Assertion::CodeRef
directly, it is more usually used indirectly via
Test::Unit::Test::assert, which instantiates a
Test::Unit::Assertion::CodeRef when passed a Coderef as its first
argument. 

=head1 IMPLEMENTS

Test::Unit::Assertion::CodeRef implements the Test::Unit::Assertion
interface, which means it can be plugged into the Test::Unit::TestCase
and friends' C<assert> method with no ill effects.

=head1 DESCRIPTION

This class is used by the framework to allow us to do assertions in a
'functional' manner. It is typically used generated automagically in
code like:

    $self->assert(sub {$_[0] == $_[1] || die "Expected $_[0], got $_[1]"},
                  1, 2); 

(Note that if Damian Conway's Perl6 RFC for currying ever comes to
pass then we'll be able to do this as:

    $self->assert(^1 == ^2 || die "Expected ^1, got ^2", 1, 2)

which will be nice...)

If you have a working B::Deparse installed with your perl installation
then, if an assertion fails, you'll see a listing of the decompiled
coderef (which will be sadly devoid of comments, but should still be
useful) 

=head1 AUTHOR

Copyright (c) 2001 Piers Cawley E<lt>pdcawley@iterative-software.comE<gt>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item *

L<Test::Unit::TestCase>

=item *

L<Test::Unit::Assertion>

=back
