package Test::Unit::Result;
use strict;
use constant DEBUG => 0;

use Test::Unit::ExceptionFailure;
use Test::Unit::Error;

use Error qw/:try/;

sub new {
    my $class = shift;
    bless {
           _Failures  => [],
           _Errors    => [],
           _Listeners => [],
           _Run_tests => 0,
           _Stop      => 0,
    }, $class;
}

sub tell_listeners {
    my $self = shift;
    my $method = shift;
    foreach (@{$self->listeners}) {
        $_->$method(@_);
    }
}
sub add_error { 
    my $self = shift;
    print ref($self) . "::add_error() called\n" if DEBUG;
    my ($test, $exception) = @_;
    push @{$self->errors()}, $exception;
    $self->tell_listeners(add_error => @_);
}

sub add_failure {
    my $self = shift;
    print ref($self) . "::add_failure() called\n" if DEBUG;
    my ($test, $exception) = @_;
    push @{$self->failures()}, $exception;
    $self->tell_listeners(add_failure => @_);
}

sub add_pass {
    my $self = shift;
    print ref($self) . "::add_pass() called\n" if DEBUG;
    my ($test) = @_;
    $self->tell_listeners(add_pass => @_);
}

sub add_listener {
    my $self = shift;
    print ref($self) . "::add_listener() called\n" if DEBUG;
    my ($listener) = @_;
    push @{$self->listeners()}, $listener;
}

sub listeners {
    my $self = shift;
    return $self->{_Listeners};
}

sub end_test {
    my $self = shift;
    my ($test) = @_;
    $self->tell_listeners(end_test => $test);
}

sub error_count {
    my $self = shift;
    return scalar @{$self->{_Errors}};
}

sub errors {
    my $self = shift;
    return $self->{_Errors};
}
 
sub failure_count {
    my $self = shift;
    return scalar @{$self->{_Failures}};
}

sub failures {
    my $self = shift;
    return $self->{_Failures};
}

sub run {
    my $self = shift;
    my ($test) = @_;
    printf "%s::run(%s) called\n", ref($self), $test->name() if DEBUG;
    $self->start_test($test);
    $self->run_protected($test, sub { $test->run_bare() && $self->add_pass($test) });
    $self->end_test($test);
} 

sub run_protected {
    my $self = shift;
    my $test = shift;
    my $closure = shift;

    try {
        &$closure();
    }
    catch Test::Unit::ExceptionFailure with {
        $self->add_failure($test, shift);
    }
    catch Test::Unit::Error with {
        $self->add_error($test, shift);
    };
}

sub run_count {
    my $self = shift;
    return $self->{_Run_tests};
}

sub run_count_inc {
    my $self = shift;
    ++$self->{_Run_tests};
    return $self->{_Run_tests};
}
    
sub should_stop {
    my $self = shift;
    return $self->{_Stop};
}
    
sub start_test {
    my $self = shift;
    my ($test) = @_;
    $self->run_count_inc();
    $self->tell_listeners(start_test => $test);
}

sub stop {
    my $self = shift;
    $self->{_Stop} = 1;
}

sub was_successful {
    my $self = shift;
    return ($self->failure_count() == 0) && ($self->error_count() == 0);
}

sub to_string {
    my $self = shift;
    my $class = ref($self);
    print $class . "::to_string() called\n" if DEBUG;
}

1;
__END__


=head1 NAME

Test::Unit::Result - unit testing framework helper class

=head1 SYNOPSIS

This class is not intended to be used directly 

=head1 DESCRIPTION

This class is used by the framework to record the results of tests,
which will throw an instance of a subclass of Test::Unit::Exception in
case of errors or failures.

To achieve this, this class gets called with a test case as argument.
It will call this test case's run method back and catch any exceptions
thrown.

This is the quintessential call tree of the communication needed to
record the results of a given test:

    $aTestCase->run() {
	# creates result
	$aTestResult->run($aTestCase) { 
	    # catches exception and records it
	    $aTestCase->run_bare() {
		# runs test method inside eval
		$aTestCase->run_test() {
		    # calls method $aTestCase->name() 
		    # and propagates exception
		    # method will call Assert::assert() 
		    # to cause failure if test fails on 
		    # test assertion
		    # it finds this because $aTestCase is-a Assert
		}
	    }
	}
    }

=head1 AUTHOR

Copyright (c) 2000 Christian Lemburg, E<lt>lemburg@acm.orgE<gt>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

Thanks go to the other PerlUnit framework people: 
Brian Ewins, Cayte Lindner, J.E. Fritz, Zhon Johansen.

=head1 SEE ALSO

=over 4

=item *

L<Test::Unit::Assert>

=item *

L<Test::Unit::TestCase>

=item *

L<Test::Unit::Exception>

=back

=cut