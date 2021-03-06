#!/bin/bash

# This file is part of Whonix
# Copyright (C) 2012 - 2013 adrelanos <adrelanos at riseup dot net>
# See the file COPYING for copying conditions.

## Whonix /etc/profile.d/80_desktop.sh

if [ ! "$(tty)" = "/dev/tty1" ]; then
   return 0
else
   scriptname="/etc/profile.d/80_desktop.sh RAM Adjusted Desktop Starter"

   error_handler() {
      echo "$scriptname ERROR: ret: $?"
      echo "$scriptname ERROR: BASH_COMMAND: $BASH_COMMAND"
   }

   maybe_start_whonixsetup() {
      ## Checking if Tor has been enabled.
      ## (For now, always 1 (yes) on Whonix-Workstatio, so is skipped on WHonix-Workstation.)
      ## And if Tor has not been enabled, auto start whonixsetup.
      ## This function only gets called, if we are not booting into a graphical desktop environment.
      ## Eventually auto starting whonixsetup in a graphical desktop environment is implemented
      ## through /etc/xdg/...

      source /usr/lib/whonix/whonixcheck/17_check_tor_enabled

      ## disable trap /usr/lib/whonix/whonixcheck/17_check_tor_enabled may have enabled
      trap "" ERR

      ## Check if Tor is enabled.
      ## returns: TOR_ENABLED
      check_tor_enabled_do

      ## disable trap of check_tor_enabled_do
      trap "" ERR

      if [ "$TOR_ENABLED" = "0" ]; then
         ## This has a sudoers exception in /etc/sudoers.d/whonixsetup.
         sudo /usr/bin/whonixsetup
      fi
   }

   for i in /etc/whonix.d/*; do
      if [ -f "$i" ]; then
         ## If the last character is a ~, ignore that file,
         ## because it was created by some editor,
         ## which creates backup files.
         if [ "${i: -1}" = "~" ]; then
            continue
         fi
         ## Skipping files such as .dpkg-old and .dpkg-dist.
         if ( echo "$i" | grep -q ".dpkg-" ); then
            true "skip $i"
            continue
         fi         
         source "$i"
      fi
   done

   ## Sanity Tests, Defaults, Debugging
   if [ -z "$whonixdesktop_debug" ]; then
      whonixdesktop_debug=0
   fi
   if [ "$whonixdesktop_debug" = 1 ]; then
      set -x
   fi
   if [ -z "$whonixdesktop_display_manager" ]; then
      whonixdesktop_display_manager=kdm
   fi
   if [ -z "$whonixdesktop_minium_ram" ]; then
      whonixdesktop_minium_ram=500
   fi
   if [ -z "$whonixdesktop_start_display_manager" ]; then
      whonixdesktop_start_display_manager=1
   fi
   if [ -z "$whonixdesktop_skip_ram_test" ]; then
      whonixdesktop_skip_ram_test=0
   fi
   if [ -z "$whonixdesktop_wait" ]; then
      whonixdesktop_wait=1
   fi
   if [ -z "$whonixdesktop_wait_seconds" ]; then
      whonixdesktop_wait_seconds=10
   fi
   if [ -z "$whonixdesktop_autostart_decision_feature" ]; then
      whonixdesktop_autostart_decision_feature=1
   fi
   
   if [ ! "$whonixdesktop_autostart_decision_feature" = "1" ]; then
      if [ "$whonixdesktop_debug" = 1 ]; then  
         true "$scriptname INFO: whonixdesktop_autostart_decision_feature is not set to 1, doing nothing."
         set +x
      fi
      return 0
   fi

   which "$whonixdesktop_display_manager" >/dev/null
   ret="$?"

   if [ ! "$ret" = "0" ]; then
      if [ "$whonixdesktop_debug" = 1 ]; then
         true "$scriptname INFO: display manager \
$whonixdesktop_display_manager configured in /etc/whonix.d/ \
configuration folder does not exist. Not starting a desktop environment."
         set +x
      fi
      maybe_start_whonixsetup
      return 0
   fi

   ## There is a /etc/sudoers.d/kdm exception for this.
   sudo service "$whonixdesktop_display_manager" status >/dev/null
   ret="$?"

   if [ "$ret" = "0" ]; then
      if [ "$whonixdesktop_debug" = 1 ]; then
         true "$scriptname INFO: \
Not starting kdm, already running."
         set +x
      fi
      ## return, not exit, because this file gets sourced (not executed)
      ## by /etc/profile.
      return 0
   fi

   if [ "$whonixdesktop_debug" = 1 ]; then
      temp="$scriptname INFO: $(/bin/date) | \
      whoami: $(/usr/bin/whoami) | caller: $0 | path: $PATH"
      true "$temp"
      echo "$temp" >> ~/whonixdesktop
      chown --recursive user:user ~/whonixdesktop
      chmod --recursive g+w ~/whonixdesktop
      chmod --recursive o+w ~/whonixdesktop
   fi

   ## Check how much RAM the system has in total.
   ## Thanks to:
   ## http://stackoverflow.com/a/10277712
   total_ram="$(free -m | sed  -n -e '/^Mem:/s/^[^0-9]*\([0-9]*\) .*/\1/p')"

   if [ "$whonixdesktop_start_display_manager" = 0 ]; then
      if [ "$whonixdesktop_debug" = 1 ]; then
         true "$scriptname INFO: \
whonixdesktop_start_display_manager is set to 0 in /etc/whonix.d/ \
configuration folder, not starting a desktop environment."
         set +x
      fi
      maybe_start_whonixsetup
      return 0
   fi

   if [ ! "$whonixdesktop_skip_ram_test" = "1" ]; then
      if [ "$total_ram" -lt "$whonixdesktop_minium_ram" ]; then
         echo "$scriptname INFO: Not starting login manager \
(graphical desktop environment) ($whonixdesktop_display_manager), \
because there is only "$total_ram" MB total RAM. (A minimum of \
"$whonixdesktop_minium_ram" MB total RAM is configured in /etc/whonix.d/ \
configuration folder.)"
         maybe_start_whonixsetup
         return 0
      fi
   fi

   if [ "$whonixdesktop_wait" = "0" ]; then
      if [ "$whonixdesktop_debug" = 1 ]; then
         true "$scriptname INFO: Waiting feature disabled."
      fi
   else
      echo "$scriptname INFO: Starting login manager \
(graphical desktop environment) "$whonixdesktop_display_manager" in \
"$whonixdesktop_wait_seconds" seconds, unless you abort using ctrl + c. \
This can be disabled or configured in /etc/whonix.d/ configuration folder."
   fi

   if [ -e "/usr/share/whonix/whonix_gateway" ]; then
      echo "If your host has little RAM, you are advised to reduce Whonix-Gateway RAM to 128 MB. No graphical desktop environment will be started in that case. A Whonix-Gateway without graphical desktop environment works as good as one with, it's just not that convenient. If you want, you can sometimes start a graphical desktop environment and sometimes only a terminal by toggling how much RAM is available to Whonix-Gateway. Documentation about this feature can be found here: https://www.whonix.org/wiki/Desktop"
   fi

   ## Fallback.
   sleep_return="0"

   ## Returns 0, if sleep was not terminated (CTRL + C not pressed) , otherwise 1.
   /usr/lib/whonix/desktop_sleep "$whonixdesktop_wait_seconds" || { sleep_return="$?" ; true; };

   if [ "$sleep_return" = "0" ]; then
      ## There is a /etc/sudoers.d/kdm exception for this.
      sudo /usr/sbin/service "$whonixdesktop_display_manager" start
      ret="$?"
   else
      ## We will not boot into a graphical desktop environment.
      maybe_start_whonixsetup
   fi

   if [ "$whonixdesktop_debug" = 1 ]; then
      true "$scriptname INFO: End."
      set +x
   fi

fi

## End of Whonix /etc/profile.d/80_desktop.sh
