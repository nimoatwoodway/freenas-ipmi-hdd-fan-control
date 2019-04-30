# freenas-fpmi-hdd-fan-control
Script for controlling fans by reading hdd temps and using ipmi tool from super micro.

Many thanks to the origin author! Made little adjustments to run with my specific super micro board and setup.

## Infos to use ipmi ##
https://anysrc.net/post/sonstiges/supermicro-ipmi-fan-control-rpm

## Script origin and infos from origin author ##
This script works on SuperMicro X9 and X10 IPMI motherboards to control FANA Peripheral
Zone fan speed in response to maximum hard drive temperature.

To use this correctly, you should connect all your PWM HD fans, by splitters if necessary to the FANA header. 
Case and Exhaust fans should then be connected to the numbered (ie CPU based) headers.  This script will then control the
HD fans in response to the HD temp, and allow the system to control the other fans in response to the CPU temp.

It should be set as a cron job to run on roughly a three minute interval, or alternatively
you can set a loop_sleep value, and it will loop indefinately after loop_sleep seconds.

you can see debug output by setting the debug_mode value to a greater value than 0. higher
values are more detailed.

Remember to adjust the configuration values below.

In order for these duty cycle changes to work, you need to ensure that you’ve adjusted your fan thresholds as per:
https://forums.freenas.org/index.php?threads/how-to-change-sensor-thresholds-with-ipmi-using-ipmitool.23571/

The original version of this script was developed by Kevin Horton and can be found at:
https://forums.freenas.org/index.php?threads/script-to-control-fan-speed-in-response-to-hard-drive-temperatures.41294/page-3#post-282683

This version was modified by myself (stux), to support systems where the HD fans are connected to
the peripheral fan headers (ie FANA). I corrected a number of issues with reading the temperature from Seagate
drives, as well as made the temperature configurable, corrected a few timing issues, and added the loop_seconds, max_allowed_temp and
debug constructs

More information on CPU/Peripheral Zone can be found in this post:
https://forums.freenas.org/index.php?threads/thermal-and-accoustical-design-validation.28364/

And the Duty Cycle/Zone commands are found in these posts
https://forums.freenas.org/index.php?threads/script-to-control-fan-speed-in-response-to-hard-drive-temperatures.41294/page-4#post-289940
https://forums.freenas.org/index.php?threads/script-to-control-fan-speed-in-response-to-hard-drive-temperatures.41294/page-4#post-290054
https://forums.servethehome.com/index.php?resources/supermicro-x9-x10-x11-fan-speed-control.20/


Version History
#--------------------
1.x Kevin's scripts
2.0 stux: initial changes to support a FANA/Zone 1 based system
2.1 stux: added initial setting to Optimal mode. Increased delay before reset to 10 seconds. Fixed date/time logging bug


if loop_sleep is non-zero, then we'll never exit. Its how long, in seconds, we should sleep each iteration...
