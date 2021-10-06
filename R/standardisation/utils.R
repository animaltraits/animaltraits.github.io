# The animal traits database
# Written in 2021 by Jim McLean jim_mclean@optusnet.com.au
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# General functions which don't fit elsewhere

FirstNonBlank <- function(v) v[v != ""][1]

TrimWS <- function(str) ifelse(is.null(str), str, gsub("^[[:space:]]+|[[:space:]]+$", "", str))


