#!/bin/bash

# -a tells emacsclient what command to use as an alternate if it can't find a running Emacs server process. Giving it the empty string (“”) as an argument is a special flag which means “start a new Emacs process as a daemon in the background, and then try again to connect”

TERM="xterm-256color"
echo -ne '\033]12;10\007'
emacsclient -t -a '' $*
