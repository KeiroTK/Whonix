#!/bin/bash

# This file is part of Whonix
# Copyright (C) 2012 - 2013 adrelanos <adrelanos at riseup dot net>
# See the file COPYING for copying conditions.

## Whonix /etc/profile.d/30_timesync.sh

if [ ! "$(tty)" = "/dev/tty1" ]; then
   return 0
else
   ## The delay is just for the look and feel.
   /usr/lib/whonix/delay sudo -u user /usr/lib/whonix/doutput --identifier timesync --icon /usr/share/whonix/icons/timesync.ico --showcli & disown
fi

## End of Whonix /etc/profile.d/30_timesync.sh
