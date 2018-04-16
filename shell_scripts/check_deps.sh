#!/bin/bash

# Copyright (C) 2016 Franz Flasch <franz.flasch@gmx.at>

# This file is part of REM - Rake for EMbedded Systems and Microcontrollers.

# REM is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# REM is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with REM.  If not, see <http://www.gnu.org/licenses/>.


# This script will perform the following tests:
# At first a recursive "compile test" build with the complete package dependency chain will be done. 
# In each round one specific dependency will be disabled and checked if the build is still successful.
# If one build is successful, the disabled dependency comes to the list of "suspicious" packages.
# 
# The second part is the link test.
# As it cannot be guaranteed that every package on the "suspicous" compile test list is 100% a wrong dependency setting
# an additional link test will be done.
#
# Consider the following scenario:
# The compile test could expose that the dependency ATMEGA168 from the package heatingctrl is suspocious.
# However this does not mean, that the dependency setup is wrong! If there are generic headers used with different implementations, 
# then this cannot be detected by the compile test alone!
# In this case the script checks if more packages with the same dependency exists and are "suspicious"
# If all packages with the suspicous dependency are in the "suspicious" list then they are considered for doing a link test.
# The link test will start linking without the given packages which were chosen before for doing this test. If one link build succeeds
# without the given dependency then the probability for a wrong dependency setup is plausible and they also come to the link dependency list.
# If some packages are contained in both lists, then these packages can be considered as nearly 100% wrong configured!
#
# If one package (from the complete dependency chain) with the given suspicous dependency is not in the "suspicious" compiletest list,
# then this would mean, that at least one compilation failed, and therefore the dependency setting for this one package is correct,
# it also means that it is not necessary to do a link test then, as this will fail for sure

if [ -z "$PACKAGE_NAME" ]; then
    echo "PACKAGE_NAME not set!"
    exit 1
fi

# Do a normal build at first to check if everything is OK
rem package:$PACKAGE_NAME:link
if [ "$?" != 0 ]; then
    echo "Not able to do a normal build! Check if you can build normally before doing a dependency test!"
    exit 2
fi


# Helper functions
function add_to_array_if_not_contained()
{
    array_ref=$1
    text_to_append=$2
    eval "array=\${$array_ref[*]}"

    if [[ "${array[@]}" =~ "${text_to_append}" ]]; then
        echo "ARRAY ALREADY CONTAINS $text_to_append!"
        return
    else
        array+=("$text_to_append")
    fi

    eval "$array_ref+=($text_to_append)"
}


# Get the complete dependency of the package, the last sed command removes the color from the output
DEPENDENCY_CHAIN=`rem package:$PACKAGE_NAME:depends_chain_print | awk '/DEPENDENCY-CHAIN:/{y=1;next}y' | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g'`

COMPILE_TEST_RESULT=()
DEP_LIST_ARRAY=()

# Now build each package from the dependencylist while removing a single dependency in each iteration
# If one of the build iterations is successful, then there's probably something wrong in the dependency settings
for pkg in $DEPENDENCY_CHAIN
do
    echo ""
    echo "Checking package $pkg"
    deps_for_package=`rem package:$pkg:depends_chain_print | grep "$pkg -->"`
    if [ "$?" != 0 ]; then
        echo "No deps for package $pkg! Continuing..."
        continue
    fi

    deps_for_package=`echo $deps_for_package | awk '{$1=$2="";$0=$0;$1=$1}1' | sed 's/\x1b\[[0-9;]*m//g'`
    echo "$pkg has the following dependencies: $deps_for_package"

    DEP_LIST_ARRAY+=("$pkg : $deps_for_package")


    for dep in $deps_for_package
    do
        echo "Trying to build $pkg without $dep"
        rem package:$pkg:clean[compile]
        rem package:$pkg:check_deps[$dep,"compile",$PACKAGE_NAME]
        if [ "$?" != 0 ]; then
            echo "Error when building $pkg without $dep"
        else
            echo "Build without $dep possible! Please check deps for package $pkg!!"
            COMPILE_TEST_RESULT+=("$pkg : $dep")
        fi
    done
done


# COMPILE_TEST_RESULT=()
# COMPILE_TEST_RESULT+=("heatingctrl : ATMEGA168")
# COMPILE_TEST_RESULT+=("heatingctrl : crc")
# COMPILE_TEST_RESULT+=("msglib : crc")
# COMPILE_TEST_RESULT+=("soft_spi : spi_common")
# COMPILE_TEST_RESULT+=("ATMEGA168 : spi_common")

LINK_REMOVE_ARRAY=()
CANDIDATE_DEP_COUNT_ARRAY=()
for each in "${COMPILE_TEST_RESULT[@]}"
do
    canditate=`echo $each | awk '{print $3}'`

    canditate_count=0
    for each in "${COMPILE_TEST_RESULT[@]}"
    do
        canditate_tmp=`echo $each | awk '{print $3}'`
        if [ "$canditate" == "$canditate_tmp" ]; then
            canditate_count=$(( $canditate_count + 1))
        fi
    done
    #echo "$canditate occurences in result: $canditate_count"

    dep_count=0
    for each in "${DEP_LIST_ARRAY[@]}"
    do
        dep=`echo $each | awk '{print $1}'`
        if [ "$canditate" == "$dep" ]; then
            # ignore this package as it is the one we are currently checking
            continue
        fi
        dep_count=$(( $dep_count +`echo "$each" | grep -o "$canditate" | wc -l` ))
    done
    #echo "Count $canditate : $dep_count"

    if [ $canditate_count -eq $dep_count ]; then
        echo "$canditate has same occurences in dep_list as in the result list! Candidate for link test!"
        add_to_array_if_not_contained "LINK_REMOVE_ARRAY" "$canditate"
        add_to_array_if_not_contained "CANDIDATE_DEP_COUNT_ARRAY" "$canditate\ -\ occurences\ deplist:\ $dep_count,\ occurences\ compile\ testresult:\ $canditate_count"
    fi
done


# Do final link test here:
LINK_TEST_RESULT=()
for each in "${LINK_REMOVE_ARRAY[@]}"
do
    rem package:$PACKAGE_NAME:clean["link"]
    rem package:$PACKAGE_NAME:check_deps[$each,"link",$PACKAGE_NAME]
    if [ "$?" != 0 ]; then
        echo "Error when linking $PACKAGE_NAME without $each"
    else
        echo "Linking without $each possible! Please check if $each is really necessary in your deps!"
        LINK_TEST_RESULT+=("$each")
    fi
done


echo ""
echo ""
echo "==============================================="
echo "Dependency analysis results:"
echo "==============================================="
echo ""
echo "The result of this script contains testresults of compiling and linking packages without specific dependencies."
echo " - If the result of the compile test is empty, then the probability of a correct dependency setup is ~100%"
echo " - If the result of the compile test not empty, but the result of the link test is empty then the probability of a correct dependency setup is high but not 100%"
echo "   in this case the results of the compile test should be checked for correctness"
echo " - If the compile test is not empty and also the link test is not empty, then the packages which are on both lists are practically 100% wrong"
echo " - If the compile test is empty but the link test is not, then there is something seriously wrong. This should not happen."
echo ""
echo "Compile test result:"
echo "suspicious packages:"
if [ -n "$COMPILE_TEST_RESULT" ]; then
    for each in "${COMPILE_TEST_RESULT[@]}"
    do
        echo "$each"
    done
else
    echo "NONE"
fi

echo ""
echo ""
echo "Candidates chosen for link test:"
if [ -n "$CANDIDATE_DEP_COUNT_ARRAY" ]; then
    for each in "${CANDIDATE_DEP_COUNT_ARRAY[@]}"
    do
        echo "$each"
    done
else
    echo "NONE"
fi

echo ""
echo "Link test result:"
echo "suspicious packages:"
if [ -n "$LINK_TEST_RESULT" ]; then
    for each in "${LINK_TEST_RESULT[@]}"
    do
        echo "$each"
    done
else
    echo "NONE"
fi
