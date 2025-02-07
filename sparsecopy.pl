#!/usr/bin/perl -w
# sparsecopy.pl=head1 NAME

=head1 NAME

sparsecopy.plx

=head1 SYNOPSIS

 Useage: sparsecopy.plx [source-dir [target-dir [ext ]]]]
 
     where:
        -s, --source       source-dir            source directory
        -t, --target       target-dir            target directory
        -e, --ext          ext                   extension of files to copy
        -f, --force        overwrite all existing targets
        -u, --update       update old target with newer source file
        -i, --interactive  prompt whether to overwrite target file
        -v, --verbose      verbose execution
        -h, --help
          
=head1 DESCRIPTION

 create target directory tree
 copy files with extension ext into target directory tree

=head1 DEPENDENCIES

none

=cut
#
#
# Dependencies:
#
#
use strict;
use warnings;
use Shell qw(cd ls);
use Pod::Usage;		#print a usage message from embedded pod documentation
use Getopt::Long;
use Cwd;
use File::Basename;
use File::Find;
use File::Path;
use File::Spec;
sub shell_cmd; #execute shell command (may be piped) w/ no return value
sub remove_pre_post_whitespace;   # remove whitespace
sub escape;    # escape special characters for command line processing

#
# Get parameters
#
Getopt::Long::Configure('auto_abbrev', 'permute', 'bundling');
my $source = '.';
my $target = '/mnt/usb';
my $ext = "";
my $force = 0;	#overwrite all existing targets
my $update = 0; #update old target with newer source file
my $prompt = 0; #prompt whether to overwrite target file
my $verbose = 0;
my $help = 0;
GetOptions("source=s" => \$source, "s=s" => \$source,
           "target=s" => \$target,"t=s" => \$target,
           "ext=s" => \$ext,"e=s" => \$ext,
	   "update"  => \$update,"u"  => \$update,
	   "force"  => \$force,"f"  => \$force,
	   "interactive"  => \$prompt,"i"  => \$prompt,
	   "verbose"  => \$verbose,"v"  => \$verbose,
           "help" => \$help,"h" => \$help);
if ($help) {
    pod2usage(-verbose => 2);
    exit;
}
#
# Check for proper useage
#
if (length($source) == 0) {
    pod2usage(-verbose => 2);
    exit;
}
#
# add extensions
#
my @ext = length($ext)?$ext:"";
my $k =   length($ext)?1:0;
for (@ARGV){$ext[$k++] = $_;}


my %options = (wanted => \&wanted, preprocess => \&preprocess, postprocess =>\&postprocess);
my $cwd     = getcwd();
my $src     = ($source eq "." || $source eq "./") ? $cwd:$source;

print "+++++++++++++++++++\n";
print "Source Directory:\t$source\n";
print "Target Directory:\t$target\n";
$k = join(" ",@ext);
print "file extension:\t\t$k\n";
print "Update:\t\t$update\n";
print "Force Overwrite:\t\t$force\n";
print "Interactive prompt:\t\t$prompt\n";
print "Verbose:\t\t$verbose\n";
print "+++++++++++++++++++\n";
my ($abs_target, $esc_abs_target, $abs_source);

if ( !-d $source ) {die "can't find directory $source $!"}
else{
 my $src = escape($source);
 $abs_source = shell_cmd("bash -c 'cd $src; pwd'");
 $abs_source =~ s/\n//g;
 }
if ( !-d $target ) {die "can't find directory $target ***$!***"}
else{
 my $trgt = escape($target);
 $abs_target = shell_cmd("bash -c 'cd $trgt; pwd'");
 $abs_target =~ s/\n//g;
 $esc_abs_target = escape($abs_target);
 }
if($verbose == 1) { 
  print "Current Directory:\t$cwd\nAbsolute Source:\t$abs_source\nAbsolute target:\t$abs_target\n";
  print "+++++++++++++++++++\n";
}
#
# query for confirmation of values
#
print "Continue processing (Y/n)?";
my $yn = lc(getc(STDIN));
if($yn =~ /n/) {exit};

my $cp = ($verbose)?"cp -va ":"cp -a ";
find(\%options, $source);

#
# wanted function for File::Find
#
sub wanted{
   my $rel_dest = $File::Find::dir;
   $rel_dest =~ s/$source//;	#relative subdirectory w/r to source
   my $cp_status = "";
   my $yn = "";
   my $trgt;
   my $ofile = $_;

   $ofile = escape($ofile);
   my $esc_rel_dest = escape($rel_dest);
   #
   # process file
   #
   if (-f $_) {
    #
    # does file exist in target directory?
    #
    if(-f $abs_target.$rel_dest."/".$_){
       #
       # update mode?
       #
       if($update){
          $cp_status = qx($cp -u $ofile $esc_abs_target$esc_rel_dest);
          if($?){ die "Copying $_ to $esc_abs_target$esc_rel_dest failed $!\n"}
       }
       #
       # overwrite mode?
       #
       elsif($force){
          $cp_status = qx($cp -f $ofile $esc_abs_target$esc_rel_dest);
          if($?){ die "Copying $_ to $esc_abs_target$esc_rel_dest failed $!\n"}
       }
       #
       # query for confirmation to overwrite existing file
       #
       else{
          print "Overwrite $esc_abs_target$esc_rel_dest/$_ (Y/n/All/Update/aBort)?";
          $yn = lc(getc(STDIN));
          print "\n";
          if($yn =~ /[Yy]/ ){ # | $yn =~ /\n/){
             $cp_status = qx($cp -f $ofile $esc_abs_target$esc_rel_dest);
             if($?){ die "Copying $_ to $esc_abs_target$esc_rel_dest failed $!\n"}
             }
          elsif($yn =~ /[Uu]/){
             $update = 1;
             $cp_status = qx($cp -u $ofile $esc_abs_target$esc_rel_dest);
             if($?){ die "Copying $_ to $esc_abs_target$esc_rel_dest failed $!\n"}
             }
          elsif($yn =~ /[Aa]/){
             $force = 1;
             $cp_status = qx($cp -f $ofile $esc_abs_target$esc_rel_dest);
             if($?){ die "Copying $_ to $esc_abs_target$esc_rel_dest failed $!\n"}
             }
          elsif($yn =~ /[Bb]/){
             exit;
             }
        }  
       }  # if(-f $abs_target.$rel_dest."/".$_)
       #
       # file is NOT in target
       #
       else{
          $cp_status = qx($cp $ofile $esc_abs_target$esc_rel_dest);
          if($?){ die "Copying $_ to $esc_abs_target$esc_rel_dest failed $!\n"}
          }
       print $cp_status;
       }  # if (-f $_)
}
#
# preprocess function for File::Find
#
sub preprocess{
   my ($base, $path, $suf, @n);
   my $i =0;
   my $e;
   foreach (@_){
   ($base, $path, $suf) = fileparse($_,qr{\..*$});
     if ( -d $_) {
      push @n, $_;}
     elsif (-f $_) {   #add files to process
      LINE: foreach $e (@ext){
          if($suf =~ /\.$e$/){
             ++$i;
             push @n, $_;
             last LINE;
           }
      }
      #print "$_\n";
     }
   }

   if($i){
      if($verbose == 1) { print "+++++++++++++++++++\n$File::Find::dir \n+++++++++++++++++++\n";}
      my $rel_dest = $File::Find::dir;
      $rel_dest =~ s/$source//;	#relative subdirectory w/r to source
      eval { mkpath($abs_target.$rel_dest, 1, 644) };
      if ($@) {
          print "Couldn't create $target.$File::Find::dir: $@";
      }
    }

    return @n;
}
#
# postprocess function for File::Find
#
sub postprocess{
}
#
#execute command in the shell
#
sub shell_cmd{
  if($#_>0){ print $_[0], "\n";} #display command
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
    $s =~ s/>/\\>/g;     #escape imbedded redirection in filename
    $s =~ s/&/\\&/g;     #escape imbedded background in filename
    $s =~ s/\|/\\\|/g;  #escape imbedded pipe in filename
    return $s;
}
