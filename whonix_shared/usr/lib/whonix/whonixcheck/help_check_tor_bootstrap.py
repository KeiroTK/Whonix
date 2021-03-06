#!/usr/bin/python

# This file is part of Whonix
# Copyright (C) 2012 - 2013 adrelanos <adrelanos at riseup dot net>
# See the file COPYING for copying conditions.

import sys
import os.path
import stem

from stem.control import Controller

if os.path.exists("/usr/share/whonix/whonix_workstation"):
  p=9151
elif os.path.exists("/usr/share/whonix/whonix_gateway"):
  ## Control Port Filter Proxy listens on 9052 on Whonix-Gateway
  p=9052
else:
  exit_code=254
  sys.exit(exit_code)

try:
  with Controller.from_port(port = p) as controller:
    ## Authentication not necessary when using Control Port Filter Proxy.
    #controller.authenticate("password")

    bootstrap_status = controller.get_info("status/bootstrap-phase")    
    
    ## Possible answer, if network cable has been removed:
    ## 250-status/bootstrap-phase=WARN BOOTSTRAP PROGRESS=80 TAG=conn_or SUMMARY="Connecting to the Tor network" WARNING="No route to host" REASON=NOROUTE COUNT=26 RECOMMENDATION=warn
    
    ## Possible answer:
    ## 250-status/bootstrap-phase=NOTICE BOOTSTRAP PROGRESS=85 TAG=handshake_or SUMMARY="Finishing handshake with first hop"

    ## Possible answer, when done:
    ## 250-status/bootstrap-phase=NOTICE BOOTSTRAP PROGRESS=100 TAG=done SUMMARY="Done"
    
    ## TODO: parse the messages above.
    
    print "%s" % (bootstrap_status)
 
    b = bootstrap_status.split( )
    
    #c = ''.join(b[3])
    #d = c.split('=')
    #e = d[1]
    #print "%s" % (e)

    progress = b[2]
  
    progress_percent = ( progress.split( "=" ) )[1]
  
    #print "progress_percent: %s" % (progress_percent)

    exit_code=int(progress_percent)
    
except:
  exit_code=255
  
sys.exit(exit_code)
