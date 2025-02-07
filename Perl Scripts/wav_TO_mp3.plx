#!/usr/bin/perl -w
# wav_TO_mp3.plx

=head1 NAME

wav_TO_mp3.plx

=head1 SYNOPSIS

 Useage: wav_TO_mp3.plx working-dir
 
     where:
        working-dir            working directory for *.ogg, *.mp3
          
=head1 DESCRIPTION

 encode each file into ogg wrapped flac file,
 normalize the pcm data and
 encode file into an mp3 audio file

=head1 DEPENDENCIES

 lame        mp3 encoder
 sox         sound exchange

=cut
#
#
# Dependencies:
#
#
use strict;
# use warnings;
use Shell qw(ls cat cdparanoia);

#
# Get command line arguments
#
my $dir    = (@ARGV >  0) ? $ARGV[0]:".";    #work directory
my @track;   #track number
my @vol;     #sox normalizing volume 
my $i = 0;
my $k;
my $l; #current line from file
my $infile;
my $outfile;
my $soxstat = "$dir/soxstat.txt";
my $soxvol = "$dir/soxvol.txt";
my $device = "-d/dev/sr1";
my $cdparanoiaQ = "cdparanoia $device -Q 2>";
my $cdparanoiaR = "cdparanoia $device";
my $flac = "flac --best --ogg";
#
# check for applications
# required by this script
#
my @dependencies = ("lame sox");
for (@dependencies) {check_dependencies($_);}
#
# range check
#
#
# Current directory contains flac encoded audio files
#
@track = qx(ls *.wav);
if ($?) {
    print "*** Can't open find any *.wav files to process: $! ***\naborting now...\n";
    print "\n";
    exit;
}
#
# remove line feeds
$i = 0; for (@track){$track[$i++] =~ s/\n//g;}

print "+++++++++++++++++++\n";
print "Files to process:\t$track[0] ... $track[$#track]\n";
print "Working directory:\t$dir\n";
print "Encode each file into ogg wrapped flac file, normalize the pcm data and encode file into an mp3 file\n";
print "+++++++++++++++++++\n";
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};

print "\n";
open VOL_FH, ">$soxvol" or die "Can't open $soxvol: $!";

$i=0; for (@track){
    #
    # normalize volume
    # Encode to mp3
    #
    $k = $i +1;   #track number starting from 1

    print "\n...processing $_\n";
    $infile = escape($_);
    $outfile = $_;
    $outfile =~ s/\.wav$//;
    $outfile = escape($outfile);
    qx(flac --best --ogg -f $infile -o $outfile.ogg);
    qx(flac -dc $outfile.ogg | sox -twav - -e stat -v 2> $soxstat);
    open ST_FH, "$soxstat" or die "Can't open $soxstat: $!";
    $vol[$i] = <ST_FH>;
    $vol[$i] =~ s/\n//g;  #remove carriage return/line feed
    close ST_FH;
    print VOL_FH "$_ \t$vol[$i]\n";
    print "Normalizing volume: $vol[$i] \n";
    qx(flac -cd $outfile.ogg | sox -twav -v $vol[$i] - -twav - | lame -h -mm -b64 - $outfile.mp3);
    
}
close VOL_FH;
qx(rm $soxstat);
#
# check for applications
# required by this script
#
sub check_dependencies{
my $exec;
for $exec (@_) {
    qx(which $exec);
    if ($? != 0) {
              print "***$exec not found - required by script***\naborting now...\n";
              exit;}
}}
#
# escape special characters for command line processing
#
sub escape {
 my $s = $_[0];
    $s =~ s/'/\\'/g;     #escape imbedded quotes in filename
    $s =~ s/"/\\"/g;     #escape imbedded quotes in filename
    $s =~ s/`/\\`/g;     #escape imbedded quotes in filename
    $s =~ s/ /\\ /g;     #escape imbedded spaces in filename
    $s =~ s/\(/\\\(/g;   #escape imbedded parens. in filename
    $s =~ s/\)/\\\)/g;   #escape imbedded parens. in filename
    $s =~ s/\[/\\\[/g;   #escape imbedded parens. in filename
    $s =~ s/\]/\\\]/g;   #escape imbedded parens. in filename
    $s =~ s/>/\\>/g;     #escape imbedded redirection in filename
    $s =~ s/&/\\&/g;     #escape imbedded background in filename
    $s =~ s/\|/\\\|/g;  #escape imbedded pipe in filename
    return $s;
}
