#!/usr/bin/perl -w

=head1 NAME
 
 oggTOmp3_.plx

=head1 SYNOPSIS

    Combine several flac (with ogg wrapper) encoded wav files
 into single mp3 encoded audio file. Recurses through each directory of form 
 discnn.

 Required directory structure of working directory:
 
   disc1, disc2, ... , discdd
   where each subdirectory discdd contains *.ogg wav files to be mp3 encoded

=head1 OPTIONS:

  -f  --file
       file mode - process individual files given on command line
       (versus directory mode which processes all *.ogg files in directories disc1, ..., discdd)
  -n, --nfile = 1 
       number of files encoded into each output file 
  -w, --working-dir = current directory
       working directory
  -o, --out-dir = working directory
       output directory for *.mp3 files
  -v, --verbose = off
       level of verbosity
  -p, --prefix = 'disc'
       directory prefix, filename defaults to dd-nn.mp3
          where dd is directory number i.e. 01 => prefix1, 11 => prefix11, ...
	        nn is track number (based on order of *.ogg files in prefixdd)
  -h, --help
  
=head1 DEPENDENCIES

 flac    free lossless audio codec
 lame    mp3 encoder
 sox     sound exchange

=cut
#
use strict;
use warnings;
use Pod::Usage;		#print a usage message from embedded pod documentation
use Cwd;		#Cwd - get pathname of current working directory
use Getopt::Long;
use Shell qw(ls cat);
sub shell_cmd; #execute shell command (may be piped)
my $pwd = getcwd;
my $chapter;
my $i;
my $n;
my $k;
my $dir;
my $mode;	#directory mode
my $outfile;
my $flacparams = "--force-raw-format --endian=little --sign=signed";
my $soxparams = "-r44100 -s -w -c2";
my $lameparams = "-s 44.1 --bitwidth 16-ms";
my $soxvol;
my $volume;
#
# Get parameters
#
Getopt::Long::Configure('auto_abbrev', 'permute', 'bundling');
my $out_dir = '';
my $wrk_dir = '.';
my $nfile = 1;
my $prefix = "disc";
my $verbose = 0;
my $help = 0;
GetOptions("working-dir=s" => \$wrk_dir, "w=s" => \$wrk_dir,
           "out-dir=s" => \$out_dir, , "o=s" => \$out_dir,
           "nfile=i" => \$nfile,"n=i" => \$nfile,
           "prefix=s" => \$prefix,"p=s" => \$prefix,
           "file" => \$mode,"f" => \$mode,
           "help" => \$help,"h" => \$help,
	   "verbose"  => \$verbose,"v"  => \$verbose);
$out_dir = (length($out_dir))?$out_dir:$wrk_dir;
if ($help) {
eval{pod2usage(-verbose => 2)};	#trap fatal errors
warn() if $@;			#display warning message and continue processing
exit;
};
#
# check for applications
# required by this script
#
my @dependencies = ("flac", "lame", "sox");
for (@dependencies) {check_dependencies($_);}
#
#
#
if(!$mode){
#
# get directories to process
#
$prefix =~ s/'|"|`//g;
$prefix =~ s|/|_|g;
$prefix =~ s/:|\s/_/g;
#
# check for valid directories
#
$prefix = escape($prefix);
$wrk_dir = escape($wrk_dir);
my @dir = shell_cmd("ls -d $wrk_dir/$prefix*",0);
if ($?) {
    print "*** can't find any directories of form ${prefix}nn to process***\naborting now...\n";
print "\n";
    exit;
}
#
$i = 0;
for (@dir){
    $dir[$i] = escape($dir[$i]);
    $dir[$i++] =~ s/\n//g;
}
#
# check for *.ogg files
#
shell_cmd("ls $dir[0]/*ogg",0);
if ($?) {
    print "*** can't find any *.ogg files in $dir[0] to process***\naborting now...\n";
print "\n";
    exit;
}
#
# check for *.mp3 files
#
$out_dir = escape($out_dir);
shell_cmd("ls $out_dir/*mp3",0);
if (!$?) {
    print "*** there are *.mp3 files in $out_dir ***\naborting now...\n";
print "\n";
    exit;
}


print "+++++++++++++++++++\n";
print "Directories to process:  ".join(" ",@dir)."\n";
print "\n";
print "Output directory: $out_dir\n";
print "Naming *.mp3 files: dd-tt.mp3\n";
print "Combining $nfile *.flac into each mp3 file.\n";
print "+++++++++++++++++++\n";

#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};
#
# directory loop
#
for $dir (@dir){
#
# Current directory contains flac encoded audio files
#
my @flac = shell_cmd("ls $dir/*.ogg",0);
if ($? !=0) {
    print "\n\n*** can't find any *.ogg files to process***\naborting now...\n";
    exit;
}
#
$i = 0;
for (@flac){
    $flac[$i] = escape($flac[$i]);
    $i++;
}
my $disc_no = substr($dir,length("$wrk_dir/$prefix"));    #assuming format of $prefixnn
$disc_no =~ s/\n//g;
#
# Combine nfile files into single mp3 audio file
#
$n = ($disc_no<10 && length($disc_no)==1)?"0$disc_no":"$disc_no";    #disc number
$soxvol = "soxvol-$n.txt";
#$soxvol = "$dir/soxvol-$n.txt";
open VOL_FH, ">$soxvol" or die "Can't open $soxvol: $!";
#
# file loop
#
for ($i = 0; $i <= $#flac/$nfile; $i++){
  # current set of files to combine
  if($nfile>1){
     $chapter = join(' ',@flac[$i*$nfile..($i+1)*$nfile-1]); #list of flac files to combine into single mp3 file
   }
  else {
     $chapter = $flac[$i];
}
  $chapter =~ s/\n//g;  #remove carriage return/line feed
  #
  # Get normalizing volume
  #
  $volume = shell_cmd("flac -dc $flacparams $chapter | sox -traw $soxparams - -e stat -v 2>&1",0); #get volume of "joined.wav" by redirecting STDERR to STDOUT
  $volume =~ s/\n//g;  #remove carriage return/line feed
  print VOL_FH "$chapter\t $volume\n";
  #
  # current output filename
  #
  $n = $i + 1;
  $k = ($n<10)?"0$n":"$n";                      #track number
  $n = ($disc_no<10 && length($disc_no)==1)?"0$disc_no":"$disc_no";    #disc number
  $outfile = $n."-".$k.".mp3"; #combine prefix with current file number
  #
  # Normalize and Encode to mp3
  #
  print "Directory $dir of $dir[$#dir]\n";
  print "Normalizing and encoding to $out_dir/$outfile\n";
  print "Normalizing volume: $volume \n";
  if ($volume != 1) {
     shell_cmd("flac -dc $flacparams $chapter | sox -v $volume -traw $soxparams - -twav - | lame -mm -h -b64 - $out_dir/$outfile",0);} #normalize volume
  else{
     shell_cmd("flac -dc $flacparams $chapter | sox -traw $soxparams - -twav - | lame -mm -h -b64 - $out_dir/$outfile",0);} #normalize volume
} # end file loop
} # end directory loop
}
else{
#
# File Mode - process individual files given on command line
# (versus directory mode which processes all *.ogg files in directories disc1, ..., discdd)
#
$k = $#ARGV + 1;
print "+++++++++++++++++++\n";
print "$k files to process:  ".join(" ",@ARGV)."\n";
print "\n";
print "Output directory: $out_dir\n";
print "Appending *.mp3 to encoded files\n";
print "Combining $nfile *.flac into each mp3 file.\n";
print "+++++++++++++++++++\n";
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};
#
#
#
  $soxvol = "$wrk_dir/soxvol.txt";
  open VOL_FH, ">$soxvol" or die "Can't open $soxvol: $!";
#
# file loop
#
for $chapter (@ARGV){
  #
  # Get normalizing volume
  #
  $volume = shell_cmd("flac -dc $flacparams $chapter | sox -traw $soxparams - -e stat -v 2>&1",0); #get volume of "joined.wav" by redirecting STDERR to STDOUT
#  $volume =~ s/\n//g;  #remove carriage return/line feed
#  print VOL_FH "$chapter\t $volume\n";
  #
  # current output filename
  #
  $outfile = "$chapter.mp3"; #combine prefix with current file number
  #
  # Normalize and Encode to mp3
  #
  print "File $chapter of $#ARGV files\n";
  print "Normalizing and encoding to $out_dir/$outfile\n";
  print "Normalizing volume: $volume \n";
  if ($volume != 1) {
     shell_cmd("flac -dc $flacparams $chapter | sox -v $volume -traw $soxparams - -twav - | lame -mm -h -b64 - $out_dir/$outfile");} #normalize volume
  else{
     shell_cmd("flac -dc $flacparams $chapter | sox -traw $soxparams - -twav - | lame -mm -h -b64 - $out_dir/$outfile");} #normalize volume
}	#file loop    
}	#File Mode
#
#
#
close VOL_FH;
#
#execute command in the shell
#
sub shell_cmd{
  if($#_> 0){print $_[0], "\n";} #display command
  qx($_[0]);         #backquotes - execute command in shell
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
__END__
