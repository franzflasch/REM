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

## Example of how to load the hex file into an atmega168 microcontroller.
avrdude -F -cstk500v2 -P/dev/ttyUSB0 -patmega168p -Uflash:w:workdir/avr_atmega168/deploy/test_project/test_project.hex
