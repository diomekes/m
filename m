#!/usr/bin/env bash
#
# Find and play your music, fast. Run 'm -h' for details.
#
# Copyright (C) 2017 Arnaud VALLETTE d'OSIA
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# leave empty if m detects it correctly
readonly forced_music_path=""
readonly music_player_exec="mpv --no-video"
readonly music_shuffle_arg="--shuffle"
readonly script_version_nb="2017.06.16"

# -------------------------- Do not edit from here -------------------------- #

# Load xdg-user-dirs (https://www.freedesktop.org/wiki/Software/xdg-user-dirs/ )
readonly xdg_userdirs_file="${XDG_CONFIG_HOME:=$HOME/.config}/user-dirs.dirs"
[[ -f "${xdg_userdirs_file}" ]] && . "${xdg_userdirs_file}"

readonly m_script_path=$(dirname "$0")
readonly m_script_name=$(basename "$0")
readonly download_path="$(dirname "$(mktemp -u)")/m_cache"
readonly music_db_file="${XDG_CACHE_HOME:-$HOME/.cache}/arnaudv6_m.idx"

path_to_music="${XDG_MUSIC_DIR%/:-$HOME/Music}"
[[ -z "${forced_music_path}" ]] || path_to_music="${forced_music_path}"
path_to_music="${path_to_music%/}"

readonly m_usage_help_text="\
-------------------------------------------------------------------------------
  $0 - version: ${script_version_nb}

${m_script_name} searches your music by file and directory names. Not id-tags.
  ${m_script_name} will pipe your selection to your player (by default, mpv).
  If search returns no match, it proposes to search with youtube-dl, see '-y'.
  Depending on backend player, ${m_script_name} may support playlists files.

Usage:            ${m_script_name} [-u] [-h] [-v] [-y] [-c] [<SEARCH TERMS>]
Example:          ${m_script_name} radiohead creep

  -h, -v          Print this help text, and exit.

  -u, --update    Update or create a plain-text index-file of your music files.
                  File is named arnaudv6_m.idx and placed in XDG_CACHE_HOME, or
                  by default in '$HOME/.cache/'.
                  Music is searched in XDG_MUSIC_DIR, '\$HOME/Music' by default.
                  Alternatively, you can force a music path by editing m.

  -o              When multiple files match <SEARCH TERMS>, play first at once.

  -s              Pass shuffle argument to player.

  -y              Force ${m_script_name} to ignore any local match.
                  Instead ${m_script_name} will search with youtube-dl,
                  download the first match to a temp file, play it
                  and keep the download in a temp file for ulterior play.

  -c              Clear any music downloaded by youtube-dl and kept temporarly.

  <SEARCH TERMS>  Space separated search terms. Do not use apostrophe in terms.
-------------------------------------------------------------------------------"

# Functions
ext_with_msg() { echo "$1"; exit; }
test_bin_dep() {
    type "$1" >/dev/null 2>&1 && return 0
    echo >&2 "Could not find $1 executable."
    return 1
}

# Parse arguments from command-line
search_terms=()
for var in "$@" ; do
    if [[ "${var}" == -*  ]] ; then
        case ${var} in
            "-u" | "--update" ) update_index_f=1 ;;
            "-o" )              m_oneshot_mode=1 ;;
            "-s" )              shuffle_player=1 ;;
            "-a" )              m_all_mode=1 ;;
            "-c" )              clear_yt_cache=1 ;;
            "-y" )              search_on_ytdl=1 ;;
            * )                 ext_with_msg "${m_usage_help_text}" ;;
        esac
    else
        search_terms+=("${var}")
    fi
done

sentaku="sentaku"
# If need be, search for sentaku in script's directory
test_bin_dep sentaku >/dev/null 2>&1 || sentaku="${m_script_path}/sentaku"

# If sentaku still not found, propose to download it
test_bin_dep ${sentaku} || {
    url="https://raw.githubusercontent.com/rcmdnk/sentaku/master/bin/sentaku"
    echo "sentaku is a shell script provided by rcmdnk under MIT license."
    echo "Download it to ${m_script_path}? (y/N)"
    read -rs -t 10 -n 1 var
    # consume eventual remaining chars
    read -sr -t0.0001
    [[ ${var} =~ ^[Yy]$ ]] || ext_with_msg "No: quitting."
    wget -P "${m_script_path}" "${url}"
    chmod +x "${m_script_path}/sentaku"
    test_bin_dep ${sentaku} || exit 1
}

# Check player dependency
command_array=($music_player_exec)
[[ "${shuffle_player}" ]] && command_array+=("${music_shuffle_arg}")
test_bin_dep "${command_array[0]}" || \
    ext_with_msg "Consider editting $0 to set \$music_player_exec."

# Interactively clear cache
[[ "${clear_yt_cache}" ]] && {
    rm -r -i "${download_path}"
    exit
}

# Create/refresh index-file
[[ "${update_index_f}" ]] && {
    # in my case, triming the path on each of 17820 lines
    # saves 23 chars to display in sentaku, 0.5Mo of the 1.5Mo index file

    # find "${path_to_music}" -mindepth 1 -printf "%P\n"
    # is faster, but -printf' flag is not portable on BSDs
    var="$(find -L "${path_to_music}" -type d \
        | cut -c$((${#path_to_music}+2))- | sed 's/$/\//' )"
    var+=$'\n'
    var+="$(find -L "${path_to_music}" -type f \
        | cut -c$((${#path_to_music}+2))- )"
    echo "$var" | sort > "${music_db_file}"
    echo "updated music index file"
    [[ "${#search_terms[@]}" -gt 0 ]] && exit
}

[[ -f "${music_db_file}" ]] || \
    ext_with_msg "no index file : create one with '-u'. Use '-h' for help"

[[ "$search_on_ytdl" ]] || music_list=$(< "${music_db_file}")

# Is music_list less than 50 bytes ?
[[ ${#music_list} -lt 50 ]] && \
    echo "Index-file is questionably short: consider editing
    $0 to set 'forced_music_path' variable, and running:
    ${m_script_name} -u"

for var in "${search_terms[@]}" ; do
    music_list=$( echo "${music_list}" | grep -i "${var}" )

    # Choose only files in all mode to not repeat tracks 
    [[ ${m_all_mode} ]] && music_list=$( echo "${music_list}" | grep -v "/$" )
done

# Found no local match. Searching downloaded temp files for matches
[[ -z "${music_list}" ]] && {
    search_on_ytdl=1
    [[ -d "${download_path}" ]] && {
        music_list=$( find "${download_path}" -type f )
        for var in "${search_terms[@]}" ; do
            music_list=$( echo "${music_list}" | grep -i "${var}" )
        done
    }
}

# No local/temp file matches: does user want to search youtube ?
[[ -z "${music_list}" ]] && {
    echo "No file matches. Get first youtube result? (Y/n)"
    read -sr -t 4 -n 1 var
    # consume eventual remaining chars
    read -sr -t0.0001
    [[ ${var:=y} =~ ^[Yy]$ ]] || ext_with_msg "No: quitting."
    test_bin_dep youtube-dl || exit 1
    echo "Downloading..."
    no_space_fn=$(printf "%s" "${download_path}/${search_terms[@]}")
    youtube-dl "ytsearch:${search_terms[*]}" -f bestaudio \
        --max-filesize 40m -c -o "${no_space_fn}" -q
        # youtube-dl creates download_path if need be
    [[ -f "${no_space_fn}" ]] || ext_with_msg "Match is >40mb. Quitting."
    music_list="${no_space_fn}"
}

# User wants to play first match at once
[[ "$m_oneshot_mode" ]] && music_list="$( echo "${music_list}" | head -n 1 )"

# Can not colorize and filter results at once, for coloring changes words. Thus
# ~$ echo "radiohead" | grep --color=always "o" | grep --color=always "radio"
# gives no result. And grep has no AND operator. Now do we colorize.
[[ -z ${search_terms} ]] || {
    filter="^|$(echo "${search_terms[*]}" | sed 's/ /|/g')"
    music_list="$( echo "${music_list}" | grep -i --color=always -E "$filter" )"
}

# If there are multiple matches, allow user to make a selection
# sentaku emacs-mode' filter-as-you-type is great but pressing 'q' won't quit.
[[ -z "$m_all_mode" ]] && [[ "$( echo "${music_list}" | wc -l )" -gt 1 ]] && {
    music_list="$( echo "${music_list}" | ${sentaku} -N -s $'\n' )"
    [[ -z "${music_list}" ]] && ext_with_msg "user interruption"
}

# press space in sentaku for multi-selection. Produced string separator is \n.
IFS=$'\n'
for var in ${music_list} ; do
    # remove coloring
    var="$( echo "${var}" | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" )"
    [[ "$search_on_ytdl" ]] || var="${path_to_music}/${var}"
    [[ -f "${var}" || -d "${var}" ]] && (${command_array[@]} "$var")
done

