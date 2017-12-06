#!/bin/ksh -p
#
# sasbatch_usermods.sh
#
# This script extends sasbatch.sh.  Add local environment variables
# to this file so they will be preserved.
#

set -A USERMODS_OPTIONS   # initialize empty list
# build up list by un-commenting (and adding) the lines you need (one line per token)
# then replace the <argument> with the values you want for each token on the command line
USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="-errorabend"
USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="-xcmd"
#USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="<argument>"
#USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="<argument>"
#USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="<argument>"
#USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="<argument>"
#USERMODS_OPTIONS[${#USERMODS_OPTIONS[*]}]="<argument>"
