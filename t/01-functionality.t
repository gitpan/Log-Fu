#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use IO::String;
my $fh = IO::String->new();

require "Log/Fu.pm";
Log::Fu->import({level => "warn", target => $fh});
*set_log_level = \&Log::Fu::set_log_level;


sub check_output {
    my $regex = shift;
    $fh->seek(0);
    my $line = $fh->getline();
    $fh->truncate(0);
    if (!$regex) {
        #Negative check:
        return !$line;
    }
    return 0 if !$line;
    diag "$line";
    return $line =~ $regex;
}

log_debug("INFO MESSAGE");
ok(check_output(undef), "INFO doesn't display");

log_warn("WARN MESSAGE");
ok(check_output(qw/WARN MESSAGE/), "WARN DISPLAYS");

ok(set_log_level(__PACKAGE__, "DEBUG"), "changing log level to DEBUG");

log_debug("DEBUG MESSAGE POST LEVEL SET");
ok(check_output(qr/DEBUG MESSAGE POST LEVEL SET/), "DEBUG displays");

ok(set_log_level(__PACKAGE__, "ERR"), "changing log level to ERR");
log_warn("This warning message shouldn't appear");
ok(check_output(undef), "WARN doesn't display");

ok(set_log_level(__PACKAGE__, "DEBUG"), "changed log level to debug");
foreach my $lvl qw(debug info warn err crit) {
    no strict "refs";
    &{"log_$lvl"}($lvl);
    ok(check_output(qr/$lvl/i), "$lvl printed");
}

ok(Log::Fu::start_syslog(), "syslog wrapper open");
eval { log_err("This is a dummy message");
       log_err("Hello sysadmin.. I'm talking to YOU!")
};
ok(!$@, "Logging to syslog: $@");

ok(Log::Fu::stop_syslog(), "syslog wrapper close");

check_output(); #Rewind the stream..

log_errf("ALL YOUR %s ARE BELONG TO %s", "BASE", "US");
ok(check_output(qr/ALL YOUR BASE ARE BELONG TO US/), "log_*f functions");

log_errf("Simple unformatted message");
ok(check_output(qr/Simple unformatted message/), "simple unformatted with *f");

done_testing();