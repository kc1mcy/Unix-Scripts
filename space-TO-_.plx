#!/usr/bin/perl
# :vim syn=perl
#
use strict;
use warnings;
use Shell qw(ls mv);

our $VERSION = '0.9';

my @files = qx("ls");

#
# query for confirmation of values
#
print "Replace ' ' with '_' for all filenames in this directory\n";
print "\t$files[0]";
print "\t...\n";
print "\t$files[$#files]";
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};

for (@files) {
	$_ =~ s/\n//g;
	my $of = $_;	
	$of =~ s/\ /_/g;	
	$_ =~ s/\ /\\\ /g;	
	print $_." ".$of."\n";
	qx(mv $_ $of);
}
