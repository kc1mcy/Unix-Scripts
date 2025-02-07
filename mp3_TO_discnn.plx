#!/usr/bin/perl -w
# MP3_TO_DISCnn.plx=head1 NAME

=head1 NAME

MP3_TO_DISCnn.plx

=head1 SYNOPSIS

 Useage: MP3_TO_DISCnn.plx -m min -i in-dir -o out-dir
  
     where:
        -m, --min         number of minutes to split input-files into
        -i, --in-dir      input directory
        -o, --out-dir     mp3 output directory
        -n, --normalize   normalize the amplitude of each mp3 file
        -v, --verbose     verbose excution
        -h, --help

     where:
        input-file             mp3 input file
        working-dir            working directory for *.mp3
          
=head1 DESCRIPTION

 processes a directory of *.mp3 audio files, spliting each large mp3 file into min size files and moves them to dirnn
 rename to nn-01.mp3, nn-02.mp3, ...
 create and move to directories discnn/nn-01.mp3, discnn/nn-02.mp3, ...

=head1 DEPENDENCIES

 mp3check    checks mp3 parameters
 mp3splt     mp3 spliting utility

=cut
#
#
#
#
use strict;
use warnings;
use Cwd;
use File::Path;
use Shell qw(ls cat cdparanoia);
use Getopt::Long;
sub shell_cmd; #execute shell command (may be piped) w/ no return value
sub escape;    # escape special characters for command line processing

my $indir;
my @infile;
my $filelist;
my $vol;     #sox normalizing volume 
my $min = 6;
my $outdir = ".";
my $normalize = 0;
my $verbose = 0;
my $help = 0;
#
# Get parameters
#
Getopt::Long::Configure('auto_abbrev', 'permute', 'bundling');
GetOptions("in-dir=s" => \$indir, "i=s" => \$indir,
           "min=s" => \$min,"m=s" => \$min,
           "out-dir=s" => \$outdir,"o=s" => \$outdir,
	   "normalize"  => \$normalize,"n"  => \$normalize,
	   "verbose"  => \$verbose,"v"  => \$verbose,
           "help" => \$help,"h" => \$help);
#
# Get command line arguments
#
if(@ARGV >  0){$min   = $ARGV[0];}   #length of split mp3 files
if(@ARGV >  1){$indir = $ARGV[1];}   #input filename 
if(@ARGV >  2){$outdir   = $ARGV[2];}   #work directory
if(@ARGV >  3){$verbose   = $ARGV[3];}   #verbose
if ($help) {
    pod2usage(-verbose => 2);
    exit;
}
my $soxstat = "$outdir/soxstat.txt";
my $soxvol = "$outdir/soxvol";

#
# check for applications
# required by this script
#
my @dependencies = ("mp3splt mp3check");
for (@dependencies) {check_dependencies($_);}

print "+++++++++++++++++++\n";
print "Input directory:\t\t$indir\n";
print "Split length:\t\t$min\n";
print "Output directory:\t$outdir\n";
print "Output filenames:\t.../discnn/nn-tt.mp3\n";
if($normalize){
print "normalizing volume in mp3 files\n";}
if($verbose){
print "verbose\n";}
print "+++++++++++++++++++\n";

my $cwd     = getcwd();
my $indiresc = escape($indir);
print $indiresc."\n";
#if (!-d $indiresc) {die "Can't stat $indir: $!";}
qx(test -d $indiresc);
if ($? !=0) {
    print "\n\n*** can't find input directory $indiresc***...\n";
}

my $outdiresc = escape($outdir);
print $outdiresc."\n";
#if (!-d $outdir) {die "Can't stat $outdir: $!";}
qx(test -d $outdiresc);
if ($? !=0) {
    print "\n\n*** can't find output directory $outdiresc***...\n";
}
@infile = qx(ls -1 $indiresc/*.mp3);
if ($? !=0) {
    print "\n\n*** can't find any (*.mp3) mp3 files to process***   skipping directory...\n";
    next;
}

foreach (@infile){$_ = escape($_);}

my $i = 0;
my ($mode, $fs, $br, $stereo, $emph, $flags, $time, $fn);
for (@infile){
   $_ = remove_pre_post_whitespace($_);
   $_ = escape($_);     # escape special characters for command line processing i.e. spaces, parens, quotes
   my $last = $#infile+1;
   #print $_."\n";
   ($mode, $fs, $br, $stereo, $emph, $flags, $time, $fn) = split /\s+/, qx(mp3check -c $_);
   print qx(mp3check -c $_);
   $time =~ s/:\d\d$//;
   #print $time."\n";
   if ($min >= $time) {die "Can't split into $min min files - file is too short ($time min)";}
   elsif ($min < 1) {die "Can't split into $min min files - time interval is too short ($time min)";}
   $i++;
}

print "+++++++++++++++++++\n";
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};

my $nn = 0;	#dirnn count
for (@infile){
   $_ = remove_pre_post_whitespace($_);
   $_ = escape($_);     # escape special characters for command line processing i.e. spaces, parens, quotes
   my $last = $#infile+1;
   #print $_."\n";

   #get length of file
   ($mode, $fs, $br, $stereo, $emph, $flags, $time, $fn) = split /\s+/, qx(mp3check -c $_);
   $time =~ s/:\d\d$//;

   #
   # split file with overlap
   # split into $min minute cuts
   #
   my $start = 0;
   my $end = $min;
   $start = sprintf "%05s", $start;
   $start = $start.".00";
   $end = sprintf "%05s", $end;
   $end = $end.".00";

   my $i = 0;	#split count
   while ($end < $time){
      shell_cmd("mp3splt -q -d $outdir $_ $start $end 2&> /dev/null",0);
      $i++;
      $start = $i*$min - 1;
      $end = ($i+1)*$min;
      $start = sprintf "%05s", $start;
      $start = $start.".45";
      $end = sprintf "%05s", $end;
      $end = $end.".00";
   }
   #
   #remant under $min
   #
   shell_cmd("mp3splt -q -d $outdir $_ $start EOF 2&> /dev/null",0);


   my $mp3;
   my @mp3 = ls("$outdir/*00.mp3 $outdir/*EOF.mp3");	#list of mp3 files to process
   foreach (@mp3){
     $_ =~ s/\n//g;  #remove line feeds
   }

   $i = 0;	#file count
   my ($l, $outesc);
   open VOL_FH, ">$soxvol-$nn.txt" or die "Can't open $soxvol-$nn.txt: $!";
   foreach (@mp3){
      # rename
      $outesc = escape($_);   # escape special characters for command line processing
      $outesc =~ s/\.mp3|\.MP3/.mp3/;
      my $j = $i<10 ? "0$i" : $i;
      $l = $nn<10 ? "0$nn" : $nn;
      if(!($outesc =~ s/_\d+\.\d+_\d+\.\d+/-$j/)){     #replace _110.00_120.00.mp3 with dd-nn.mp3
          $outesc =~ s/_\d+\.\d+_EOF/-$j/;    #otherwise should be last part
      }
      if($normalize){
         # normalize volume
         if($verbose){print"sox $_ -e stat -v 2> $soxstat\n";}
         qx(sox $_ -e stat -v 2> $soxstat);
         open ST_FH, "$soxstat" or die "Can't open $soxstat: $!";
         $vol = <ST_FH>;
         $vol =~ s/\n//g;  #remove carriage return/line feed
         close ST_FH;
         ($mode, $fs, $br, $stereo, $emph, $flags, $time, $fn) = split /\s+/, qx(mp3check -c $_);
         print VOL_FH "$i\t$_ \t$time \t$vol\n";
         if($verbose){print "Normalizing volume: $vol \n";
                      print "sox -v $vol $_ -twav - | lame -h -mm -b64 - $outesc\n";}
         qx(sox -v $vol $_ -twav - | lame -h -mm -b64 - $outesc);
         qx( rm $_ );
      }
      else{
         if($verbose){print $_."   ".$outesc."\n";}
         qx( mv $_ $outesc );
     }
     $i++;	#update file count
   }
   close VOL_FH;
   qx( rm $soxstat );
   #
   #create directory and move files into it
   #
   my $glob = $outesc;
   $glob =~ s/..\.mp3$/\*/;	#dd-*
   my $dirnn = "disc".$l;
   $dirnn = ($outdir eq ".") ? $dirnn : $outdir."/".$dirnn;
   my $path = ( $outdir =~ m/^\// ) ? $dirnn : $cwd."/".$dirnn;  #absolute or relative path
   eval { mkpath($path, 1, 644) };
   if ($@) {print "Couldn't create $path";}
   else{ qx( mv $glob $path); 
         qx( mv $soxvol-$nn.txt $path );}
   # update counts
   $nn++;	#update directory count
   if($verbose){print "\n";}
   
}
#
#execute command in the shell
#
sub shell_cmd{
  if($#_>0){ print $_[0], "\n";} #display command
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
#
# remove whitespace
#
sub remove_pre_post_whitespace {
 my $s = $_[0];
 $s =~ s/^\s+//;         #remove leading whitespace
 $s =~ s/\s+$//;         #remove trailing whitespace
 return $s;
}
