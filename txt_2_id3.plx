#!/usr/bin/perl -w
# txt2id3.plx
#
# generate 1 text file per record
# from a comma separated values database file
#
#
# Useage: txt2id3.plx infile [output-file-prefix [disc number]]
#
#
# Dependencies
# id3v2: id3 tag editor
# id3lib-3.8.3; id3 library (required by id3v2)
#
use strict;
use warnings;
use Text::ParseWords;
use Shell qw(ls cat);
sub shell_cmd; #execute shell command (may be piped) w/ no return value

#
# Get command line arguments
#
my $infile = (@ARGV >  0) ? $ARGV[0]:"cmmddyy.txt";    #input filename
my $prefix = (@ARGV >  1) ? $ARGV[1]:"";    #output filename prefix
#my $disc_no = (@ARGV >  2) ? $ARGV[2]:"";    #disc no.
my @headings;   #record headings
my @record;
my $i = 0;
my $k;
my $l = ""; #current line from file
my @l; #parsed line
my %record;
my @outfile;
my $outfile;
my @dir;
my $dir;
my $filelist;
my %field_2_parm = (
             TITLE => "--TIT2",     #0
             YEAR => "--TYER",      #1
             AUTHOR => "--TOPE",    #2
             NARRATOR => "--TPE1",  #3
             CD => "--TSIZ",        #4
             PUBLISHER  => "--TPUB", #5
             YEAR => "--TORY",      #6
             STOCK => "--TXXX",     #7
             DATE  => "--TDAT",     #8
             COMMENTS  => "--COMM"); #9
#
# check for applications
# required by this script
#
my @dependencies = ("id3v2");
for (@dependencies) {check_dependencies($_);}
#
# read textfile
#
#print $infile."\n";
open TXT_FH, $infile or die "***Can't open $infile: $!***\n";
$i = 0;
while (<TXT_FH>){
$_ =~ s/\n//g;       #remove line feeds
$record[$i++] = $_;
}
close TXT_FH;
for (@record){print $_."\n";}
#
# get directories to process
#
@dir = shell_cmd("ls -d disc*",0);
if ($#dir == -1) {
    print "*** can't find any directories of form discnn to process...\n";
    $dir[0]=".";
    print "processing current directory @dir\n";
    }

$i = 0;
for (@dir){
    $dir[$i++] =~ s/\n//g;
}
print join(" ",@dir)."\n";

#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};
#
for $dir (@dir){
   print $dir.$infile."\n";

#
# list of mp3 filenames to process
#
$dir =~ s/\n//g;
@outfile = ls("$dir/*.mp3");
$filelist = join(" ",@outfile);    #list of filenames to process
print $filelist."\n";
$filelist =~ s/\n//g;       #remove line feeds
if ($#outfile == 0) {
    print "*** can't find any mp3 files to process***\naborting now...\n";
    exit;
}
#print $filelist."\n";
#
# create hash of field heading => field value
#
for (@record){
@l = parse_line(":",0,$_);
$record{$l[0]} = remove_pre_post_whitespace($l[1]);
}
#
# write id3 track no. tag
#
$i = 1;
for $l (@outfile){
my $last = $#outfile+1;
$l = remove_pre_post_whitespace($l);
shell_cmd("id3v2 --TRCK '$i/$last' $l",1);   #track no.
$i++;
}
#
# write id3 tags for title, album, artist, year, etc.
#
for (keys %record){
shell_cmd("id3v2 $field_2_parm{$_} '$record{$_}' $filelist");
}
#
# rename files (optional)
#
if (length($prefix)){
   my $trk = "Track: ";
   my $of;
   my $disc_no = substr($dir,4);    #assuming format of discnn
   $disc_no =~ s/\n//g;
   for (@outfile){
       $l = shell_cmd("id3v2 -l $_");           #list id3 tag
       $k = index($l,$trk);                     #find track no.
       $i = substr($l,$k+length($trk),2);       #track no.
       $i =~ s/\n//g;                           #remove line feed
       $k = ($i<10)?"0$i":$i;                   #format track no.
       $l = ($disc_no<10)?"0$disc_no":$disc_no; #format disc no.
       $of = $prefix."-".$l."-".$k.".mp3";      #add output file prefix
#       print $_."   => ".$dir."/".$of."\n";  
       shell_cmd("mv $_ $dir/$of",0);                  #rename
   }
}
}
#
#execute command in the shell
#
sub shell_cmd{
  if($#_==2){ print $_[0], "\n";} #display command
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
#
# check for applications
# required by this script
#
sub check_dependencies{
my $exec;
for $exec (@_) {
    shell_cmd("which $exec");
    if ($? != 0) {
              print "***$exec not found - required by script***\naborting now...\n";
              exit;}
}}
#      id3v2
#      Usage: id3v2 [OPTION]... [FILE]...
#      Adds/Modifies/Removes/Views id3v2 tags, modifies/converts/lists id3v1 tags
#      
  #      -h,  --help               Display this help and exit
#        -f,  --list-frames        Display all possible frames for id3v2
#        -L,  --list-genres        Lists all id3v1 genres
#        -v,  --version            Display version information and exit
#        -l,  --list               Lists the tag(s) on the file(s)
#        -R,  --list-rfc822        Lists using an rfc822-style format for output
#        -d,  --delete-v2          Deletes id3v2 tags
#        -s,  --delete-v1          Deletes id3v1 tags
#        -D,  --delete-all         Deletes both id3v1 and id3v2 tags
#        -C,  --convert            Converts id3v1 tag to id3v2
#        -1,  --id3v1-only         Writes only id3v1 tag
#        -2,  --id3v2-only         Writes only id3v2 tag
#        -a,  --artist  "ARTIST"   Set the artist information
#        -A,  --album   "ALBUM"    Set the album title information
#        -t,  --song    "SONG"     Set the song title information
#        -c,  --comment "DESCRIPTION":"COMMENT":"LANGUAGE"
#                                  Set the comment information (both
#                                   description and language optional)
#        -g,  --genre   num        Set the genre number
#        -y,  --year    num        Set the year
#        -T,  --track   num/num    Set the track number/(optional) total tracks
#      
#      You can set the value for any id3v2 frame by using '--' and then frame id
#      For example:
#              id3v2 --TIT3 "Monkey!" file.mp3
#      would set the "Subtitle/Description" frame to "Monkey!".
