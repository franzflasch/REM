# REM
Rake based buildsystem for EMbedded Systems and Microcontrollers

## How to build a hex file of the test project suited for an avr atmega168:
```Shell
rake ARCH=avr MACH=atmega168 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[hex]
```
The arguments "-m -j4" mean to build with max 4 threads simultaneously.

## How to build a binary file of the test project suited for an arm stm32f3:
```Shell
rake ARCH=arm MACH=stm32f3 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[bin]
```

## You can also add verbose output:
```Shell
rake ARCH=arm MACH=stm32f3 PROJECT_FOLDER="package test_project" -m -j4 package:test_project:image[bin] VERBOSE=1
```

## Example of how to load the hex file into an atmega168 microcontroller.
```Shell
avrdude -F -cstk500v2 -P/dev/ttyUSB0 -patmega168p -Uflash:w:workdir/avr_atmega168/deploy/test_project/test_project.hex
```

## List all available packages for this architecture:
```Shell
rake ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:list_packages
```

## Get a list of dependencies for a particular package:
```Shell
rake ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:msglib_test:depends_chain_print
```

## There is also a shell based wrapper script to start the build: 
The script basically calls rake -f "path/to/main/Rakefile" and allows to start the build outside of the REM base directory,
if added to the PATH variable:
```Shell
rem ARCH="avr" MACH="atmega168" PROJECT_FOLDER="package" package:msglib_test:depends_chain_print
```
