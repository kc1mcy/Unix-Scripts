#!/usr/bin/perl -w
# cdda2mp3.plx
#
# rip cdda audio tracks,
# normalized the pcm data and
# encode into an mp3 audio file
#
# Dependencies:
# cdparanoia cdda ripping program
# lame    mp3 encoder
# sox     sound exchange
#
# Useage: cdda2mp3 [output-file-prefix [working-dir ]]
#
#
#
use strict;
use warnings;
use Shell qw(ls cat cdparanoia);
sub shell_cmd; #execute shell command (may be piped) w/ no return value

#
# Get command line arguments
#
my $prefix = (@ARGV >  1) ? $ARGV[1]:"00";    #output filename prefix
my $dir    = (@ARGV >  0) ? $ARGV[0]:".";    #work directory
my @track;   #track number
my @time;    #length
my @vol;     #sox normalizing volume 
my $i = 0;
my $k;
my $l; #current line from file
my $outfile;
my $soxstat = "$dir/soxstat-$prefix.txt";
my $soxvol = "$dir/soxvol-$prefix.txt";
my $device = "-d/dev/sr0";
my $cdparanoiaQ = "cdparanoia $device -Q 2>";
my $cdparanoiaR = "cdparanoia $device";
my $flac = "flac --best --ogg";
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
   }
close QRY_FH;   
open VOL_FH, ">$soxvol" or die "Can't open $soxvol: $!";
#print "$#track \n";
for ($i=0; $i < $#track; $i++){
      print "Track: $track[$i] of $#track    Time: $time[$i]\n";
    #
    # normalize volume
    # Encode to mp3
    #
    $k = $i +1;   #track number strarting from 1
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
close VOL_FH;
shell_cmd("rm $soxstat");
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
