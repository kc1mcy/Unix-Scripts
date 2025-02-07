#!/usr/bin/perl -w
# csv2txt.plx
#
# generate 1 text file per record
# from a comma separated values database file
#
#
# Useage: csv2txt.plx [output-file-prefix [working-dir ]]
#
#
#
use strict;
use warnings;
use Text::ParseWords;
use Shell qw(ls cat);
sub shell_cmd; #execute shell command (may be piped) w/ no return value

#
# Get command line arguments
#
my $infile = (@ARGV >  0) ? $ARGV[0]:"cmmddyy.csv";    #input filename
my $prefix = (@ARGV >  1) ? $ARGV[1]:"rcd";    #output filename prefix
my $dir    = (@ARGV >  2) ? $ARGV[2]:".";    #work directory
my @headings;   #record headings
my @record;
my $i = 0;
my $k;
my $l; #current line from file
my $outfile;
\#
# open the csv file
#
open CSV_FH, $infile or die "Can't open $infile: $!";
# read header
$l = <CSV_FH>;
@headings = parse_line(",",0,$l);
$headings[$#headings] =~ s/\n//g; #remove line-feed
for $k (@headings){print "$k\n";}
shift @headings;
#
# read each database entry
# and output to a text file
#
while ($l = <CSV_FH>){
       @record = parse_line(",",0,$l);
       for $k (@record){print "$k\n";}
       shift @record;   #discard Record No.
       $outfile = $record[0];  #filename - title
       #remove parenthesized comments in title field
       if (($k = index($outfile,"("))>0){$outfile = substr($outfile,0,$k);}
       $outfile = remove_pre_post_whitespace($outfile);
       #replace whitespace with underscore
       $outfile =~ s/\s+/_/g;
       #replace entries similar to "******Disc_1_read_errors*******" with -error
       $outfile =~ s/\*+.*\*+/-error/g;
       #replace / \ : " ' ` with dash
       $outfile =~ s/\/|\\|:|"|'|`/-/g;
       last if ( length($outfile) == 0 );
       open TXT_FH, ">$dir/$outfile.txt" or die "Can't open $dir/$outfile: $!";
       $i = 0;
       $record[$#record] =~ s/\n//g; #remove line-feed
       for $k (@headings) { print TXT_FH "$k: $record[$i++]\n";}
       close TXT_FH;
	 }
close CSV_FH;   
#
#execute command in the shell
#
sub shell_cmd{
  print $_[0], "\n"; #display command
  qx($_[0]);         #backquotes - execute command in shell
}
#
# remove whitespace
#
sub remove_pre_post_whitespace {
 my $s = $_[0];
    $s =~ s/^\s+//;         #remove leading whitespace
    $s =~ s/\s+$//;         #remove trailing whitespace
    return $s;
}
