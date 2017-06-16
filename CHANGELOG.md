version 2017.06.16
* root music directory is shown (/) at the top when just invoking 'm'. Which allows playing all (with mpv backend)
* '-s' flag added: will shuffle playing order.

version 2017.06.10
* When using read to get user [y/n] answer, consume eventual remaining chars
* md5sum: 3c17eccb4e6f3bf9569e7caa344e6f4f
* m is now available at https://github.com/Arnaudv6/m

version 2017.06.02
* m should be compatible with bash on BSDs now (MacOS...)

version 2017.05.31
* more code cleaning

version 2017.05.24
* New option '-o' for oneshot mode
* More exception handling
* More code comments
* Better variable names

version 2016.06.21
* More cleaning... I shall be content for a while big_smile

version 2016.06.20
* Attempt to write m in cleaner bash style.

version 2016.06.18
* m's music index file is now stored in XDG_CACHE_HOME. you can safely delete "music_index.txt" file in your music directory, m will then ask for music index to be updated.
* when prompting for sentaku download, m now advertizes its author, license and the directory where it will actually download the file to.

version 2016.06.07
* Music directory is now set with respect to XDG

version 2016.06.05
* Killed a bug where a song with an apostrophe in its name would not play

version 2016.06.04
* Code cleaning

version 2016.06.02
* Corrected a bug where "m a radiohead" would return no result for all 'a' were decorated with color codes

version 2016.06.01
* Thanks to rcmdnk's hard work and support on sentaku, m now supports coloring !
* m now quits after it updated database if fed with no search term
* m now quits verbosely if no suitable result found on youtube

version 2016.03.15
* explicit default each time user is prompted with function read

version 2016.02.27b
* code refactoring, GPL
