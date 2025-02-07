#!/usr/bin/perl -w
#wma_TO_mp3.plx
=head1 NAME

wma2mp3.plx

=head1 SYNOPSIS

 Useage: wma_TO_mp3.plx -i input.wma -o output.mp3 -w wrk-dir
 
     where:
        -i, --input       wma input file
        -o, --output      mp3 output file
        -w, --wrk-dir     work directory
        -v, --verbose     verbose excution
        -h, --help
          
=head1 DESCRIPTION

  convert wma to mp3
  using 32K bit rate, stereo to mono, high quality

=head1 DEPENDENCIES

mplayer
lame

=cut
use strict;
use warnings;
use Shell qw(cd ls);
use Pod::Usage;		#print a usage message from embedded pod documentation
use Getopt::Long;
use Cwd;
#
# Get parameters
#
Getopt::Long::Configure('auto_abbrev', 'permute', 'bundling');
my $infile;
my $outfile;
my $dir = ".";
my $verbose = 0;
my $help = 0;
GetOptions("input=s" => \$infile, "i=s" => \$infile,
           "output=s" => \$outfile,"o=s" => \$outfile,
           "wrk-dir=s" => \$dir,"w=s" => \$dir,
	   "verbose"  => \$verbose,"v"  => \$verbose,
           "help" => \$help,"h" => \$help);
if ($help) {
    pod2usage(-verbose => 2);
    exit;
}
#
# Check for proper useage
#
if (!-f $infile) {
    pod2usage(-verbose => 2);
    exit;
}
print "+++++++++++++++++++\n";
print "Input:\t$infile\n";
print "Output:\t$outfile.mp3\n";
print "Work Directory:\t$dir\n";
print "Verbose:\t\t$verbose\n";
print "+++++++++++++++++++\n";
my ($abs_wrk);
if ( !-d $dir ) {die "can't find directory $dir $!"}
else{
 $abs_wrk = qx(bash -c 'cd $dir; pwd');
 $abs_wrk =~ s/\n//g;
 }

my $cwd     = getcwd();
if($verbose) { 
  print "Current Directory:\t$cwd\nWork Direcvtory:\t$dir\t$abs_wrk\n";
  print "+++++++++++++++++++\n";
}
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};
#
# Get audio parameters
#
my $ap;
my @ap = qx(mplayer -quiet -ss 999:99:99 $infile);
foreach (@ap){
  if (/AUDIO:/){
  $ap = $_;
  }
}
print "\n".$ap."\n";
#
# Parse audio parameters
# i.e. AUDIO: 22050 Hz, 2 ch, s16le, 32.0 kbit/4.54% (ratio: 4003->88200)
#
my ($srate, $chnl, $sign, $bits, $endian, $bitrate);
if( $ap =~  /(.....) Hz/ ){$srate = $1;}
if( $ap =~  /(.) ch/ ){$chnl = $1;}
if( $ap =~  /ch, (.)(..)(..)/ ){$sign = $1;$bits = $2;$endian = $3;}
if( $ap =~  /(.....) kbit/ ){$bitrate = $1;}
#print $srate." ".$chnl." ".$sign." ".$bits." ".$endian." ".$bitrate."\n";
$srate =~s/(...)$/.$1/;  #insert decimal point
$srate =~s/0*$//;   #remove trailing 0s
$endian = ($endian eq "le")?"":" -x ";
$bitrate =~ s/\..*$//; #remove decimal place and fractional part
#
# Create named pipe
#
my $pipe = "wma_TO_mp3_".$$;  #append process id
print "Named pipe(fifo): $pipe\n";
if  ( system('mknod',  $pipe, 'p') && system('mkfifo', $pipe) ){
           die "mk{nod,fifo} $pipe failed";
           }
#
#
my $mplayer = "mplayer -msglevel ao=8 -vo null -vc dummy -ao pcm:waveheader:file=$pipe";
my $sox ="sox -r $srate -c $chnl -w $pipe -twav -";
#my $sox ="sox $pipe -twav -";
my $lame = "lame -h -a -b$bitrate -";
print $mplayer." ".$infile." | ";
print $sox." | ";
print $lame." ".$dir."/".$outfile.".mp3\n";
#
# could not get mplayer to output wav/riff header to stdout!!!
# named pipe or temp file works O.K.?
# 
# piping directly into lame causes lame to assume incorrect file size
# rather than unspecified
#
qx( $mplayer $infile | $sox | $lame $dir/$outfile.mp3);
# remove named pipe
print "rm ".$pipe."\n";
qx( rm $pipe);






