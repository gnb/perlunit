package Test::Unit::TestRunner;
use strict;
use constant DEBUG => 0;

use base qw(Test::Unit::TestListener); 

use Test::Unit::TestSuite;
use Test::Unit::TestResult;

sub new {
    my $class = shift;
    my ($filehandle) = @_;
    $filehandle = \*STDOUT unless $filehandle;
    bless { _Print_stream => $filehandle }, $class;
}

sub print_stream {
    my $self = shift;
    return $self->{_Print_stream};
}

sub _print {
    my $self = shift;
    my (@args) = @_;
    local *FH = *{$self->print_stream()};
    print FH @args;
}

sub add_error {
    my $self = shift;
    my ($test, $exception) = @_;
    $self->_print("E");
}
	
sub add_failure {
    my $self = shift;
    my ($test, $exception) = @_;
    $self->_print("F");
}

sub create_test_result {
    my $self = shift;
    return Test::Unit::TestResult->new();
}
	
sub do_run {
    my $self = shift;
    my ($suite, $wait) = @_;
    my $result = $self->create_test_result();
    $result->add_listener($self);
    my $start_time = time();
    $suite->run($result);
    my $end_time = time();
    my $run_time = $end_time - $start_time;
    $self->_print("\n", "Time: ", $run_time, "\n");

    $self->print_result($result);
    
    if ($wait) {
	print "<RETURN> to continue"; # go to STDIN any case
	<STDIN>;
    }
    if (not $result->was_successful()) {
	exit(-1);
    }
    exit(0);		
}

sub end_test {
    my $self = shift;
    my ($test) = @_;
}

sub extract_class_name {
    my $self = shift;
    my ($classname) = @_;
    if ($classname =~ /^Default package for/) {
	# do something more sensible here
    }
    return $classname;
}

sub main {
    my $self = shift;
    my $a_test_runner = Test::Unit::TestRunner->new();
    $a_test_runner->start(@_);
}

sub print_result {
    my $self = shift;
    my ($result) = @_;
    $self->print_header($result);
    $self->print_errors($result);
    $self->print_failures($result);
}

sub print_errors {
    my $self = shift;
    my ($result) = @_;
    if ($result->error_count() != 0) {
	if ($result->error_count == 1) {
	    $self->_print("There was ", $result->error_count(), " error:\n");
	} else {
	    $self->_print("There were ", $result->error_count(), " errors:\n");
	}
	my $i = 0; 
	for my $e (@{$result->errors()}) {
	    $i++;
	    $self->_print($i, ") ", $e->to_string());
	}
    }
}

sub print_failures {
    my $self = shift;
    my ($result) = @_;
    if ($result->failure_count() != 0) {
	if ($result->failure_count == 1) {
	    $self->_print("There was ", $result->failure_count(), " failure:\n");
	} else {
	    $self->_print("There were ", $result->failure_count(), " failures:\n");
	}
	my $i = 0; 
	for my $e (@{$result->failures()}) {
	    $i++;
	    $self->_print($i, ") ", $e->to_string());
	}
    }
}

sub print_header {
    my $self = shift;
    my ($result) = @_;
    if ($result->was_successful()) {
	$self->_print("\n", "OK", " (", $result->run_count(), " tests)");
    } else {
	$self->_print("\n", "!!!FAILURES!!!", "\n",
		      "Test Results:\n",
		      "Run: ", $result->run_count(), 
		      " Failures: ", $result->failure_count(),
		      " Errors: ", $result->error_count(),
		      "\n");
    }
}

sub run {
    my $self = shift;
    my ($class) = @_;
    $self->_run(Test::Unit::TestSuite->new($class));
}
	
sub _run {
    my $self = shift;
    my ($test) = @_;
    my $a_test_runner = Test::Unit::TestRunner->new();
    $a_test_runner->do_run($test, 0);
}

sub run_and_wait {
    my $self = shift;
    my ($test) = @_;
    my $a_test_runner = Test::Unit::TestRunner->new();
    $a_test_runner->do_run($test, 1);
}

sub start {
    my $self = shift;
    my (@args) = @_;

    my $test_case = "";
    my $wait = 0;

    for (my $i = 0; $i < @args; $i++) {
	if ($args[$i] eq "-wait") {
	    $wait = 1;
	} elsif ($args[$i] eq "-c") {
	    $test_case = $self->extract_class_name($args[++$i]);
	} elsif ($args[$i] eq "-v") {
	    print "Test::Unit, draft version, copyright Christian Lemburg 2000\n";
	} else {
	    $test_case = $args[$i];
	}
    }
    if ($test_case eq "") {
	print "Usage Test_runner.pl [-wait] test_case_name, where name is the name of the Test_case class", "\n";
	exit(-1);
    }

    eval "require $test_case" 
	or die "Suite class " . $test_case . " not found: $@";
    no strict 'refs';
    my $suite = "$test_case"->new();
    my $suite_method = \&{"$test_case" . "::" . "suite"};
    if ($suite_method) {
	$suite = Test::Unit::TestSuite->new($test_case);
    }
    $self->do_run($suite, $wait);
}

sub start_test {
    my $self = shift;
    my ($test) = @_;
    $self->_print(".");
}

1;
