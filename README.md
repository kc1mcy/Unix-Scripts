# Scripts
Miscellaneous unix scripts.
## Perl Scripts
Scripts for processing mp3 files including id3 tags.

```
cdda_TO_mp3.plx [working-dir [output-file-prefix [first [last]]]]
``` 
     where:
.        working-dir            working directory for *.ogg, *.mp3
.        output-file-prefix     prefix-tt.ogg and prefix-tt.mp3 files are created
.        first                  first track to process
.        last                   last track to process

> rip cdda audio tracks,
> encode each track into ogg wrapped flac file,
> normalize the pcm data and
> encode track into an mp3 audio file
 
. Useage: csv2txt.plx [output-file-prefix [working-dir ]]
 
>generate 1 text file per record
>from a comma separated values database file


. Useage: MP3_TO_DISCnn.plx -m min -i in-dir -o out-dir
  
     where:
        -m, --min         number of minutes to split input-files into
        -i, --in-dir      input directory
        -o, --out-dir     mp3 output directory
        -n, --normalize   normalize the amplitude of each mp3 file
        -v, --verbose     verbose excution
        -h, --help

     where:
        in-dir             mp3 input file
        out-dir            working directory for *.mp3
          

 >processes a directory of *.mp3 audio files, spliting each large mp3 file into min size files and moves them to dirnn
 >rename to nn-01.mp3, nn-02.mp3, ...
 >create and move to directories discnn/nn-01.mp3, discnn/nn-02.mp3, ...

 
. Useage: sndtrk.plx working-dir
 
     where:
        -e, --ext         input-ext          video file extension
        -i, --input-dir   input-dir          input directory for video files (*.mp4, *.m4v)
        -w, --wrk-dir     work-dir           work directory for extracted soundtrack files (*.mp3)
        -m, --mode        mode               piped=0, temp file=1, piped cbr>1
        -v, --verbose                        verbose excution
        -h, --help
          

> extract soundtrack from each file (*.mp4, *.m4v) into named pipe,
> normalize the pcm data and
> encode file into an mp3 audio file

. Useage: sparsecopy.plx [source-dir [target-dir [ext ]]]]
 
     where:
        -s, --source       source-dir            source directory
        -t, --target       target-dir            target directory
        -e, --ext          ext                   extension of files to copy
        -f, --force        overwrite all existing targets
        -u, --update       update old target with newer source file
        -i, --interactive  prompt whether to overwrite target file
        -v, --verbose      verbose execution
        -h, --help
          
> create target directory tree
> copy files with extension ext into target directory tree

. Useage: txt2id3.plx infile [output-file-prefix [disc number]]

> generate 1 text file per record
> from a comma separated values database file

. Useage: wav_TO_mp3.plx working-dir
 
     where:
        working-dir            working directory for *.ogg, *.mp3
          
> encode each file into ogg wrapped flac file,
> normalize the pcm data and
> encode file into an mp3 audio file



