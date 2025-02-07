#!/usr/bin/perl -w
# cdda_TO_mp3.plx=head1 NAME

=head1 NAME

cdda_TO_mp3.plx

=head1 SYNOPSIS

 Useage: cdda_TO_mp3.plx [working-dir [output-file-prefix [first [last]]]]
 
     where:
        working-dir            working directory for *.ogg, *.mp3
        output-file-prefix     prefix-tt.ogg and prefix-tt.mp3 files are created
        first                  first track to process
        last                   last track to process
          
=head1 DESCRIPTION

 rip cdda audio tracks,
 encode each track into ogg wrapped flac file,
 normalize the pcm data and
 encode track into an mp3 audio file

=head1 DEPENDENCIES

 cdparanoia  cdda ripping program
 lame        mp3 encoder
 sox         sound exchange

=cut
#
#
# Dependencies:
#
#
use strict;
use warnings;
use Shell qw(ls cat cdparanoia);
sub shell_cmd; #execute shell command (may be piped) w/ no return value

#
# Get command line arguments
#
my $dir    = (@ARGV >  0) ? $ARGV[0]:".";    #work directory
my $prefix = (@ARGV >  1) ? $ARGV[1]:"00";   #output filename prefix
my $first  = (@ARGV >  2) ? $ARGV[2]:0;      #first track to process
my $last   = (@ARGV >  3) ? $ARGV[3]:0;      #last track to process
my @track;   #track number
my @time;    #length
my @vol;     #sox normalizing volume 
my $total;   #total time
my $i = 0;
my $k;
my $l; #current line from file
my $outfile;
my $soxstat = "$dir/soxstat-$prefix.txt";
my $soxvol = "$dir/soxvol-$prefix.txt";
my $device = "-d/dev/sr1";
my $cdparanoiaQ = "cdparanoia $device -Q 2>";
my $cdparanoiaR = "cdparanoia $device";
my $flac = "flac --best --ogg";
#
# check for applications
# required by this script
#
my @dependencies = ("id3v2");
for (@dependencies) {check_dependencies($_);}
#
# Query the cdda
#
my $query = "$dir/disc$prefix.txt";
#print "$query \n";
shell_cmd("$cdparanoiaQ $query");
#
# Read query file and initialize arrays @var and @val
#
open QRY_FH, $query or die "Can't open $query: $!";
# skip over header
while ( ($l = index(<QRY_FH>, "=================")) < 0){};
#
# Get Tracks and Time
#
while ($l = <QRY_FH>){
	 if (index($l,"TOTAL") < 0){
            $k = index($l,".");
#	    print $l;
            $track[$i] = substr($l,0,$k+1);    #extract track number
            $track[$i] = remove_pre_post_whitespace($track[$i]);
            $k = index($l,"[");
            $time[$i] = substr($l,$k+1);   #extract rest of line
            $k = index($time[$i],"]");
            $time[$i] = substr($time[$i],0,$k);   #extract rest of line
            $time[$i] = remove_pre_post_whitespace($time[$i]);
            $time[$i] =~ s/\n//g;          #remove line-feed
            $i++;
	 }
	 else {
#	    print $l;
            $k = index($l,"[");
            $total = substr($l,$k+1);   #extract rest of line
            $k = index($total,"]");
            $total = substr($total,0,$k);   #extract rest of line
            $total = remove_pre_post_whitespace($total);
            $total =~ s/\n//g;          #remove line-feed
	 } 
   }
close QRY_FH;
#
# range check
#
$first = ($first<1)?1:$first;
$first = ($first>$#track)?$#track:$first;
$last = ($last<1)?$#track:$last;
$last = ($last>$#track)?$#track:$last;
print "+++++++++++++++++++\n";
print "Total time:\t\t$total\n";
print "Number of tracks:\t$#track\n";
print "Processing tracks:\t$first-$last\n";
print "Working directory:\t$dir\n";
print "Processed filenames:\t$prefix-tt.ogg and $prefix-tt.mp3\n";
print "+++++++++++++++++++\n";
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};
open VOL_FH, ">$soxvol" or die "Can't open $soxvol: $!";
#print "$#track \n";
for ($i=0; $i < $#track; $i++){
    #
    # normalize volume
    # Encode to mp3
    #
    $k = $i +1;   #track number starting from 1
    if ($first <= $k and $k <= $last) {
       print "Track: $track[$i] of $#track    Time: $time[$i]\n";
       if ($k < 10) {$outfile = "$dir/$prefix-0$k"} else {$outfile = "$dir/$prefix-$k"};
       shell_cmd("$cdparanoiaR -w $k - | flac --best --ogg -f - -o $outfile.ogg");
       shell_cmd("flac -dc $outfile.ogg | sox -twav - -e stat -v 2> $soxstat");
       open ST_FH, "$soxstat" or die "Can't open $soxstat: $!";
       $vol[$i] = <ST_FH>;
       $vol[$i] =~ s/\n//g;  #remove carriage return/line feed
       close ST_FH;
       print VOL_FH "$track[$i] \t$time[$i] \t$vol[$i]\n";
       print "Normalizing volume: $vol[$i] \n";
       shell_cmd("flac -cd $outfile.ogg | sox -twav -v $vol[$i] - -twav - | lame -h -mm -b64 - $outfile.mp3");
       }
}
close VOL_FH;
shell_cmd("rm $soxstat");
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
