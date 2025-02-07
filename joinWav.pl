#!/usr/bin/perl
# :vim syn=perl
#
# joinWav.pl
#
# The program combines a string of wav of .wav files into one big one.
#
# Copyright (c) 2003-4 Benjamin C. Wilson. Released under GPL. For more information 
# on GPL licensing, visit http://www.gnu.org/licenses/gpl.html
#
use strict;
our $VERSION = '0.5';

my @rawfiles;
my $soxRAW      = 'sox -t raw -r 44100 -s -w -c 2';
my $wav2rawCMD  = 'sox -t wav -r 44100 -s -w -c 1';
my $raw2wavCMD  = 'dd if=combined.raw bs=17640 skip=0 count=';
my $pipedCMD    = " | $soxRAW - combined.wav ";


foreach my $file (@ARGV) {
	next if (! -e $file || -z $file);
	my $raw = $file;
	$raw    =~ s/wav/raw/i;
	print `$wav2rawCMD $file $raw`;
	push (@rawfiles, $raw);
}
my $cat  = join(' ', @rawfiles);
print `cat $cat > combined.raw`;
my $size = -s 'combined.raw' || 0;
print `$raw2wavCMD$size$pipedCMD`;
print `rm $cat`; # I like the idea of eliminating the cat! :-)
print "All done. Now if you want to run lame, I suggest running this command as is:\n";
print "\t' lame -h -b 128 combined.wav combined.mp3 '\n";
print "You can rename the combined.mp3 later.\n";
exit;
