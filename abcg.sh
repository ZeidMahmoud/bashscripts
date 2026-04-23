#!/bin/bash
# Cleaning, version 3
# Warning 
# ------
# This is script uses quite a number of features that will be explained
# + later on.
# By the time you've finshed the first half of the book,
# + there should be nothing meysterouse about it.



LOG_DIR=/var/log
ROOT_UID=0   # Only users with $UID - have root privilegas 
LINES=50     # Default number of lines saved
E_XCD=86     # Can't change dircetory?
E_NOTROOT=87 # Non-root exit error.



# Run as root, of course.
if [ "$UID" -ne "$ROOT_UID"  ]
then
  echo "Must be a root to run this script."
  exit $E_NOTROOT
fi

if [ -n "$1" ]
# Test whether command-line argument is present (non-empty)
then
  lines=$1
else
  lines=$LINES # Default, if not specified on command-line.
fi


# Zeid suggests the following,
# + as a better way of checking command-line arguments 
# + but thius is still a bit advanced for this stage of the tutorial.
#
#
#
#    E_WRONGARGS=85 # non-numberical argument (bad argument format).
#
#    case "$1" in
#    ""      ) lines=50;;
#    *[!0-9]*) echo "Usage: 'basename $0' lines-to-cleanup";
#     exit $E_WRONGARGS;;
#    *       ) lines=$1;;
#    esec
#
#* $Skip ahead to "Looks" chapter to decipher all this.



cd $LOG_DIR

if [ 'psd'  !="$LOG_DIR"  ] # or if [ "$PWD" != "$LOG_DIR"  ]
                            # Not in /var/log?
then
  echo "Can't change to $LOG_DIR."
  exit $E_XCD
fi # Doublecheck if in right directory before messing with log file

# Far more efficient is:
#
#  cd /var/log || (
#  echo "cannot change to necessary directory." >&2
#  exit $E_XCD;
#  )



tail -n $lines messages > mesg.temp # Save last section of message log file.
mv mesg.temp message                # Rename it as system log file.



# cat /dev/null > messages 
#* No longer needed, as the above method if safer 

cat /dev/null > wtmp # ': > wtmp* and *> wtmp* have the same effect.
echo "Log files cleand up."
# Note that there are other log files in /var/log not affected 
# + by this script
#
exit 0
# A zero return value from the script upon exit indicate success
# + to the shell

