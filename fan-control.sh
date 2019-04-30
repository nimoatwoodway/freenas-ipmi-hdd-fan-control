#!/usr/local/bin/perl

# This script works on SuperMicro X9 and X10 IPMI motherboards to control FANA Peripheral
# Zone fan speed in response to maximum hard drive temperature.

# To use this correctly, you should connect all your PWM HD fans, by splitters if necessary to the FANA header. 
# Case and Exhaust fans should then be connected to the numbered (ie CPU based) headers.  This script will then control the
# HD fans in response to the HD temp, and allow the system to control the other fans in response to the CPU temp.

# It should be set as a cron job to run on roughly a three minute interval, or alternatively
# you can set a loop_sleep value, and it will loop indefinately after loop_sleep seconds.

# you can see debug output by setting the debug_mode value to a greater value than 0. higher
# values are more detailed.

# Remember to adjust the configuration values below.

# In order for these duty cycle changes to work, you need to ensure that you’ve adjusted your fan thresholds as per:
# https://forums.freenas.org/index.php?threads/how-to-change-sensor-thresholds-with-ipmi-using-ipmitool.23571/

# The original version of this script was developed by Kevin Horton and can be found at:
# https://forums.freenas.org/index.php?threads/script-to-control-fan-speed-in-response-to-hard-drive-temperatures.41294/page-3#post-282683

# This version was modified by myself (stux), to support systems where the HD fans are connected to
# the peripheral fan headers (ie FANA). I corrected a number of issues with reading the temperature from Seagate
# drives, as well as made the temperature configurable, corrected a few timing issues, and added the loop_seconds, max_allowed_temp and
# debug constructs

# More information on CPU/Peripheral Zone can be found in this post:
# https://forums.freenas.org/index.php?threads/thermal-and-accoustical-design-validation.28364/

# And the Duty Cycle/Zone commands are found in these posts
# https://forums.freenas.org/index.php?threads/script-to-control-fan-speed-in-response-to-hard-drive-temperatures.41294/page-4#post-289940
# https://forums.freenas.org/index.php?threads/script-to-control-fan-speed-in-response-to-hard-drive-temperatures.41294/page-4#post-290054
# https://forums.servethehome.com/index.php?resources/supermicro-x9-x10-x11-fan-speed-control.20/


# Version History
#--------------------
# 1.x Kevin's scripts
# 2.0 stux: initial changes to support a FANA/Zone 1 based system
# 2.1 stux: added initial setting to Optimal mode. Increased delay before reset to 10 seconds. Fixed date/time logging bug


# if loop_sleep is non-zero, then we'll never exit. Its how long, in seconds, we should sleep each iteration...

$loop_sleep = 0; # 0 for no looping. 180 for 3 minute looping (suggested)
$debug = 4;	# 0 for no debug. 1..4 for verbosity


# edit the following values
$number_of_hard_drives = 8;
$hd_designator = "/dev/ada";
$min_fan_speed = 300;
$max_fan_speed = 1400;
$max_allowed_temp = 40;	# celsius. you will hit 100% duty cycle when you HDs hit this temp.

$LogFile = '/root/HD_TempLog.txt';
$min_fan_speed *= 1.4;
$max_fan_speed *= 0.8;

# edit nothing below this line

use POSIX qw(strftime);


# go to Optimal mode
`ipmitool raw 0x30 0x45 0x01 2`;
sleep 1;

do {

#build datestring
$datestring = strftime "%F %H:%M:%S", localtime;

open (LOGFILE, ">>$LogFile");

$max_temp = 0;

foreach $item (0..$number_of_hard_drives-1) {
  $command = "/usr/local/sbin/smartctl -A $hd_designator$item | grep Temperature_Celsius";

  if( $debug > 3) {
    print "$command\n";
  }

  $output = `$command`;
  if ($debug > 2) {
    print "$output\n";
  }

  @vals = split(" ", $output);

  # grab 4th item from the output, which is the hard drive temperature
  $temp = "$vals[9]\n";
  
  if( $debug > 1 ) {
    print "$hd_designator$item: $temp";
  } 
 
  # update maximum drive temperature
  $max_temp = $temp if $temp > $max_temp;
}

if( $debug > 0 ) {
  print "Maximum HD Temperature: $max_temp\n";
}

if ($max_temp >= $max_allowed_temp ) {

 if( $debug > 0 ) {
    print "drives are too hot, going to 100%\n";
  }

  # set hd fan speed control to 100%
  `ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x65`;
  `ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x65`;
}

elsif ($max_temp >= $max_allowed_temp - 1 ) {
    
 if( $debug > 0 ) {
    print "drives are warm, going to %75\n";
  }
    
  # set hd fans speed control to 75%
  `ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x55`;
  `ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x55`;
}

elsif ($max_temp >= $max_allowed_temp - 2 ) {
 
  if( $debug > 0 ) {
    print "drives are warming, going to 50%\n";
  }

  # set peripheral zone fan speed to 50% duty cycle
  `ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x30`;
  `ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x30`;
}

else {

  if( $debug > 0 ) {
    print "drives are cool enough, going to 25%\n";
  }
  # set to 30%
 `ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x20`;
 `ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x20`;
}

# reset BMC if temps are cool, and fan is not slow
if ($max_temp < $max_allowed_temp - 3 ){

  sleep 10; #need to wait for fans to change speed
	
  $command = "ipmitool sdr | grep FANA";
  $output = `$command`;
  @vals = split(" ", $output);
  $fan_speed = "$vals[2]";

  if ($fan_speed > $min_fan_speed){
    if( $debug > 0 ) {
      print "drives are cool ($max_temp), but fan is high ($fan_speed). resetting BMC\n";
    }

    `ipmitool bmc reset cold`;
  }
}

# reset BMC if temps are warm, and fan is not fast
if ($max_temp > $max_allowed_temp ){
  
  sleep 10; # need to wait for fans to change speed...

$command = "ipmitool sdr | grep FANA";
  $output = `$command`;
  @vals = split(" ", $output);
  $fan_speed = "$vals[2]";

  if ($fan_speed < $max_fan_speed){
    if( $debug > 0 ) {
        print "drives are hot ($max_temp), but fan is low ($fan_speed). resetting BMC\n";
    }
    `ipmitool bmc reset cold`;
  }
}

print LOGFILE "$datestring - $max_temp";
close (LOGFILE);

if( $loop_sleep > 0 ) {
  if( $debug > 2 ) {
    print "sleeping...\n";
  }
  sleep $loop_sleep;
}

} while( $loop_sleep )
