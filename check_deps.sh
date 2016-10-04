#!/bin/bash


if [ -z "$PACKAGE_NAME" ]; then
	echo "PACKAGE_NAME not set!"
	exit
fi

# Get the complete dependency of the package, the last sed command removes the color from the output
DEPENDENCY_CHAIN=`rem package:$PACKAGE_NAME:depends_chain_print | awk '/DEPENDENCY-CHAIN:/{y=1;next}y' | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g'`

RESULT=()

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

	for dep in $deps_for_package
		do
		echo "Trying to build $pkg without $dep"
		for dep_to_clean in $deps_for_package
		do
			#rem package:dirclean
			rem package:$dep_to_clean:clean[compile]
		done
		rem package:$pkg:clean[compile]
		if [ "$pkg" == "$PACKAGE_NAME" ]; then
			echo "Last entry: $pkg - we should better do linking here..."
			rem package:$pkg:check_deps[$dep,1]
		else
			rem package:$pkg:check_deps[$dep]
		fi
		if [ "$?" != 0 ]; then
			echo "Error when building $pkg without $dep"
		else
			echo "Build without $dep possible! Please check deps for package $pkg!!"
			RESULT+=("$pkg: $dep")
		fi
	done
done

rem package:$PACKAGE_NAME:link
if [ "$?" == 0 ]; then
	echo "Dependency check passed!!"
else
	echo "ERROR! Something is wrong with the final build maybe you should check if it builds in the normal case"
fi

if [ -z "$RESULT" ]; then
    echo "Dependency settings seem to be okay"
else
    echo ""
	echo "The following packages should be checked:"
	printf "%s\n" "${RESULT[@]}"
fi
