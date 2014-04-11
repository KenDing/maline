#!/bin/bash

# Copyright 2013,2014 Marko Dimjašević, Simone Atzeni, Ivo Ugrina, Zvonimir Rakamarić
#
# This file is part of maline.
#
# maline is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# maline is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with maline.  If not, see <http://www.gnu.org/licenses/>.


# Directory where the log file is
LOG_DIR=$1

# Log file to be parsed
LOG=$2

BASE_NAME=$(basename $LOG .log)
LOCK_FILE=/var/lock/.$BASE_NAME
CURR_PID=$$

# Set the strace parsing command name
STRACE_PY_SRC="$MALINE/bin/parse-strace-log.py"
COMMAND="python $STRACE_PY_SRC"
COMMAND_COMPILED="$MALINE/bin/parse-strace-log.pyc"

# if [ -e "$COMMAND_COMPILED" ]; then
#     COMMAND="$COMMAND_COMPILED"
# fi

# Clean up upon exiting from the process
function __sig_func {
    if [ -e $LOCK_FILE ]; then
	PID_IN_FILE=`cat $LOCK_FILE`
	[[ $PID_IN_FILE -eq $CURR_PID ]] && rm $LOCK_FILE || exit 1
    else
	exit 1
    fi
}

# Set traps
trap __sig_func EXIT
trap __sig_func INT
trap __sig_func SIGQUIT
trap __sig_func SIGTERM


if [ -e "$LOG_DIR/$BASE_NAME.graph" ]; then
    # Skipping $LOG because it was already parsed ...
    exit 1
fi

(
    # Test for an exclusive lock on $LOCK_FILE
    flock --exclusive --nonblock 42 || exit 1
    echo $CURR_PID > $LOCK_FILE

    echo "Parsing:     $LOG ... "
    $COMMAND $LOG
    [[ $? -eq 0 ]] && echo "Done parsing $LOG"
    
) 42> $LOCK_FILE

exit 0
