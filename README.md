# m
[bash script] finds and plays music

Comment here: https://bbs.archlinux.org/viewtopic.php?id=209369

m searches your music by file and directory names. Not id-tags.
  m will pipe your selection to your player (by default, mpv).
  If search returns no match, it proposes to search with youtube-dl.
  Depending on backend player, m may support directories and playlists-files.

Dependencies:
* a backend player: mpv/mplayer...
* [sentaku](https://github.com/rcmdnk/sentaku) (Downloaded at runtime on demand)
* youtube-dl (Optional)

