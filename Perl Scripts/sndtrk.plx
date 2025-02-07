#!/usr/bin/perl -w
# sndtrk.plx

=head1 NAME

sndtrk.plx

=head1 SYNOPSIS

 Useage: sndtrk.plx working-dir
 
     where:
        -e, --ext         input-ext          video file extension
        -i, --input-dir   input-dir          input directory for video files (*.mp4, *.m4v)
        -w, --wrk-dir     work-dir           work directory for extracted soundtrack files (*.mp3)
        -m, --mode        mode               piped=0, temp file=1, piped cbr>1
        -v, --verbose                        verbose excution
        -h, --help
          
=head1 DESCRIPTION

 extract soundtrack from each file (*.mp4, *.m4v) into named pipe,
 normalize the pcm data and
 encode file into an mp3 audio file

=head1 DEPENDENCIES

 lame        mp3 encoder
 sox         sound exchange
 mplayer     video player

=cut
#
#
# Dependencies:
#
#
use strict;             # use warnings;
use Shell qw(ls cat mplayer sox);
use Pod::Usage;		#print a usage message from embedded pod documentation
use Getopt::Long;
use Cwd;

my @ifile;   #input file array
my $ofile;   #output file
my @vol;     #sox normalizing volume 
my $i = 0;
my $k;
my $l; #current line from file
my $ap;

#
# Get command line arguments
#
Getopt::Long::Configure('auto_abbrev', 'permute', 'bundling');
my $ext = "m4v";
my $idir = ".";   #input directory
my $dir = ".";    #work directory
my $verbose = 0;
my $help = 0;
my $mode = 1;	#piped=0, temp file=1, piped cbr>1
GetOptions("input-dir=s" => \$idir, "i=s" => \$idir,
           "ext=s" => \$ext,"e=s" => \$ext,
           "mode=i" => \$mode,"m=i" => \$mode,
           "wrk-dir=s" => \$dir,"w=s" => \$dir,
	   "verbose"  => \$verbose,"v"  => \$verbose,
           "help" => \$help,"h" => \$help);
if ($help) {
    pod2usage(-verbose => 2);
    exit;
}



#
# check for applications
# required by this script
#
my @dependencies = ("lame sox mplayer");
for (@dependencies) {check_dependencies($_);}
#
# range check
#
#
# Current directory contains flac encoded audio files
#
$idir =~ s/\ /\\\ /g;
@ifile = qx(ls $idir/*.$ext);
if ($?) {
    print "*** Can't open find any video *.$ext files to process: $! ***\naborting now...\n";
    print "\n";
    exit;
}
#
# remove line feeds
$i = 0; for (@ifile){$ifile[$i++] =~ s/\n//g;}
$dir =~ s/\ /\\\ /g;

print "+++++++++++++++++++\n";
print "Mode:\t\t\t$mode ";
if($mode == 0) {print "(Piped mode)\n";}
if($mode == 1) {print "(Tmp file mode)\n";}
if($mode > 1) {print "(Piped cbr mode)\n";}
print "Input directory:\t$idir\n";
print "Video extension:\t$ext\n";
print "Files to process:\t$ifile[0] ... $ifile[$#ifile]\n";
print "Working directory:\t$dir\n";
print "extract soundtrack from each file (*.$ext) into named pipe,";
print " encode file into an mp3 audio file,";
print " encode file into an mp3 file\n";
print "+++++++++++++++++++\n";
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};
#
# Create named pipe
#
my $pipe = "pipe".$$;  #append process id
if($mode == 0 || $mode > 1)
		{
		print "Named pipe(fifo): $pipe\n";
		if ( qx(mkfifo $pipe) )	   #system('mkfifo', $pipe) )
			{
			if ( qx(mknod $pipe p) )  #system('mknod', $pipe, 'p')
				{
				#print "mkfifo $pipe failed\n";
				die "mknod $pipe failed\n";
				}	
	        	}
	  	}
my $tmp = "tmp.wav";
#

$i=0;
for (@ifile){
#escape whitespace
$_ =~ s/\ /\\\ /g;
if($mode == 0){
#	print "mplayer - extracting soundtrack from $_ to $pipe (raw pcm) file...";
#	print "  (piped mode)\n\n";
	my $mplayer = "mplayer -vo null -vc null -novideo -ao pcm:fast:file=$pipe";
#	my $lame = "lame -V0 -q0 --vbr-new $pipe";
	my $lame = "lame -h -a $pipe";
	#
	# Get audio parameters
	#
#	my @ap =qx($mplayer $_ &);	#run mplayer in background
#	my @ap = qx(mplayer -quiet -vo null -vc null -novideo -ss 999:99:99 $_);
	print "\n$mplayer $_\n";
	my @ap=qx($mplayer $_ &);
	foreach (@ap){
	  if (/AUDIO:/){
	  my $ap = $_;
	  }
	}
#	print "\n".$ap."\n";
	my $ofile = $_;
	$ofile =~ s/.$ext/.mp3/;
	qx($lame $dir/$ofile);		#take input from pipe
	}
if($mode == 1){
#	print "mplayer - extracting soundtrack from $_ to $tmp (raw pcm) file...";
#	print " (tmp file mode)\n\n";
	my $mplayer = "mplayer -vo null -vc null -novideo -ao pcm:fast:file=$tmp";
#	my $lame = "lame -V0 -q0 --vbr-new $tmp";
	my $lame = "lame -h -a $tmp";
	#
	# Get audio parameters
	#
	print "\n$mplayer $_\n";
	my @ap =qx($mplayer $_);
	foreach (@ap){
	  if (/AUDIO:/){
	  my $ap = $_;
	  }
	}
#	print "\n".$ap."\n";
	$_ =~ s/.$ext/.mp3/;
#	print "$lame $dir/$_\n"; 
	qx($lame $dir/$_);
	}
if($mode > 1){
#	print "mplayer - extracting soundtrack from $_ to $pipe (raw pcm) file...";
#	print "  (piped cbr mode)\n\n";
	#
	# Get audio parameters
	#
	my $mplayer = "mplayer -msglevel ao=8 -vo null -vc null -novideo -ao pcm:waveheader:fast:file=$pipe";
#	my @ap = qx(mplayer -quiet -vo null -vc null -novideo -ss 999:99:99 $_);
#	print $mplayer." ".$_." & ";
	print "\n".$mplayer." ".$_;
	my @ap = qx( $mplayer $_);
	foreach (@ap){
	  if (/AUDIO:/){
	  my $ap = $_;
	  }
	}
#	print "\n".$ap."\n";
	#
	# Parse audio parameters
	# i.e. AUDIO: 22050 Hz, 2 ch, s16le, 32.0 kbit/4.54% (ratio: 4003->88200)
	#
	my ($srate, $chnl, $sign, $bits, $endian, $bitrate);
#	if( $ap =~  /(.....) Hz/ ){$srate = $1;}
#	if( $ap =~  /(.) ch/ ){$chnl = $1;}
#	if( $ap =~  /ch, (.)(..)(..)/ ){$sign = $1;$bits = $2;$endian = $3;}
#	if( $ap =~  /(.....) kbit/ ){$bitrate = $1;}
	#print $srate." ".$chnl." ".$sign." ".$bits." ".$endian." ".$bitrate."\n";
#	$srate =~ s/(...)$/.$1/;  #insert decimal point
#	$srate =~ s/0*$//;   #remove trailing 0s
#	$endian = ($endian eq "le")?"":" -x ";
#	$bitrate =~ s/\..*$//; #remove decimal place and fractional part
	#
	# could not get mplayer to output wav/riff header to stdout!!!
	# named pipe or temp file works O.K.?
	# 
	# piping directly into lame causes lame to assume incorrect file size
	# rather than unspecified
	#
	#print qw( $mplayer $_ | $sox | $lame $dir/$_.mp3);
#	my $sox ="sox -r $srate -c $chnl $pipe -twav -";
#	my $lame = "lame -h -a -b$bitrate -";
	$ofile = $_;
	$ofile =~ s/.$ext/.mp3/;
	my $lame = "lame -h -a $pipe";
#	print $sox." | ";
	print $lame." ".$dir."/".$ofile."\n";
	qx( $lame $dir/$ofile );
	}
}

# remove named pipe and tmp file
print "rm ".$pipe."\n";
qx( rm $pipe $tmp);

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
