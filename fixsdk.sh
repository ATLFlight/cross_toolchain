#!/bin/bash

# Script to fix some libraries in the latest version of the Snapdragon Flight SDK (qrlSDK)
# Ths script only works with the latest version

# Verbose mode
## set -x
# Exit if any command has error
set -e

# Comment out the second line to run in debug mode (to just print but do NOT perform the actual fix)
debug=
## debug=echo

# This is assumed to be the location of qrlSDK directory installation
workspace=`pwd`
sysroots_root=${workspace}/sysroots/eagle8074

MD5_314=91c36ba4d5b986db3b0e1b01b2d97416

# Verify that the SDK is installed in the workspace
check_workspace() {

  # This script is only applicable to a certain version of the Snapdragon Flight SDK.
  # Therefore check for the presence of the correct version environment script and abort if not.
  # NOTE: This test can only be done if the user manually installed the SDK.
  if [ -d ${workspace}/sysroots ] && [ ! -e gcc-linaro-4.9.4-2017.01-x86_64_arm-linux-gnueabihf ]
  then
    echo "WARNING: SDK cleanup not required for this version. Skipping..."
    exit 0
  fi

  # Check for the presence of certain directories in the sysroots.
  if [ ! -d ${sysroots_root}/usr/lib ] || [ ! -d ${sysroots_root}/lib ] || [ ! -d ${sysroots_root}/lib/arm-linux-gnueabihf ]
  then
    echo "ERROR: Unable to locate sysroots directories. You may be running this script from the wrong workspace OR the qrl SDK may not have been installed properly."
    exit 1
  fi

  if [ -f ${sysroots_root}/QRLSDKMD5SUM ]; then
    md5sum_actual=$(cat ${sysroots_root}/QRLSDKMD5SUM)
    if [ ${md5sum_actual} != ${MD5_314} ]; then
      echo "WARNING: SDK cleanup not required for this version. Skipping..."
      exit 0
    fi
  fi
}


# Function to create non-versioned symbolic links for certain libraries that are missing
fix_missing_links() {

  # Handle the missing libcrypto case as an exception
  pushd ${sysroots_root}/lib/ > /dev/null
  if [ ! -f libcrypto.so ]; then
    $debug ln -s arm-linux-gnueabihf/libcrypto.so.1.0.0 libcrypto.so
  fi
  popd > /dev/null
  echo "Fixed crypto library."
  
  # Find all libraries of the form lib*.so.x in the lib/arm-linux-gnueabihf location.
  set +e
  libs_arm_versioned_level1=$(find ${sysroots_root}/lib/arm-linux-gnueabihf -name lib*.so.? | rev |  cut -d'/' -f1 | rev )
  set -e

  # Loop over the list of libraries and create sym links to them from within the lib directory
  fixcount=0
  lib_count=0
  index=0
  for lib_entry in ${libs_arm_versioned_level1[@]}
  do    
    pushd ${sysroots_root}/lib > /dev/null
    if [ -L "${sysroots_root}/lib/${lib_entry}" ] || [ -f "${sysroots_root}/lib/${lib_entry}" ]; then
      $debug rm -f $lib_entry
    fi
    $debug ln -s ./arm-linux-gnueabihf/$lib_entry
    popd > /dev/null
    fixcount=$((fixcount+1))
  done
  
  if [ $fixcount -eq 0 ]; then
    echo "No *.so.x libraries to fix in $lib_path".
  else
    echo "Fixed $fixcount *.so.x libraries in lib".
  fi  
}


# Fix broken library symbolic links
fix_broken_libs() {
  lib_path=$1

  cd $workspace
  
  # Find all the broken symlinks
  set +e
  broken_libs=$(find ${sysroots_root}/${lib_path} -maxdepth 1 -xtype l | grep so)
  set -e
  if [[ -z ${broken_libs} ]]; then
    echo "No broken libraries to fix in $lib_path"
    return
  fi
  
  # Loop over the list of libraries and create an array of versioned counterparts
  lib_count=0
  index=0
  for lib_entry in ${broken_libs[@]}
  do
    # Get each library (versionless)
    broken_libarray[$index]=$lib_entry
    index=$((index+1))
  done
  # Store the count of such libraries
  lib_count=$index
  
  # Loop over the list of libraries, and create symlinks
  fixcount=0
  for((index=0;index<$lib_count;index++))
  do
    broken_libarray=${broken_libarray[$index]}
    broken_lib=$(basename $broken_libarray)

    versioned_lib_fullpath=$(find ${sysroots_root}/lib/arm-linux-gnueabihf/ -maxdepth 1 -name "$broken_lib*" -print -quit)
    if [ ${#versioned_lib_fullpath} -ne 0 ]
    then
      versioned_lib_base=$(basename $versioned_lib_fullpath)
      pushd ${sysroots_root}/${lib_path} > /dev/null
      $debug rm -f $broken_lib
      $debug ln -s ../../lib/arm-linux-gnueabihf/$versioned_lib_base $broken_lib
      popd > /dev/null
      echo "Fixed $broken_lib"
      fixcount=$((fixcount+1))
    else
      echo "WARNING: Did not find libraries for $broken_lib. Skipping..."
    fi
    
  done

  if [ $fixcount -eq 0 ]; then
    echo "No broken libraries were fixed in $lib_path".
  else
    echo "Fixed $fixcount of $lib_count broken libs in $lib_path".
  fi
}


# Fix library symlinks that point to incorrect versions of actual libraries
fix_incorrect_libs() {

  lib_path=$1

  # Find all versionless library symlinks that link to the local versioned counterpart
  # Skip the ones that are already symlinked to other locations
  set +e
  libs_with_local_symlinks_versionless=$(find ${sysroots_root}/${lib_path} -maxdepth 1 -type l -ls | grep "so" | grep -v "arm-linux-gnueabihf" | rev | cut -d' ' -f3 | rev | grep -v "\.\." )
  set -e

  # Loop over the list of libraries and create an array of versioned counterparts
  lib_count=0
  index=0
  for lib_entry in ${libs_with_local_symlinks_versionless[@]}
  do
    # Get each library (versionless)
    libarray_local_symlinks_versionless[$index]=$lib_entry
    # Get the symlink target (versioned) and append to another array
    libarray_local_symlinks_versioned[$index]=$(readlink -f ${libarray_local_symlinks_versionless[$index]})
    index=$((index+1))
  done
  # Store the count of such libraries
  lib_count=$index

  # Loop over the list of libraries, remove the original, switch the symlinks
  fixcount=0
  for((index=0;index<$lib_count;index++))
  do
    lib_versioned_fullpath=${libarray_local_symlinks_versioned[$index]}
    lib_versioned=$(basename $lib_versioned_fullpath)

    if [[ ! $lib_versioned_fullpath =~ .*arm-linux-gnueabihf.* ]] && [ -f ${sysroots_root}/lib/arm-linux-gnueabihf/$lib_versioned ]
    then
      $debug rm -f $lib_versioned_fullpath | true
      pushd ${sysroots_root}/${lib_path} > /dev/null
      $debug ln -s ../../lib/arm-linux-gnueabihf/$lib_versioned $lib_versioned
      popd > /dev/null
      echo "Fixed $lib_versioned"
      fixcount=$((fixcount+1))
    fi
    
  done

  if [ $fixcount -eq 0 ]; then
    echo "No incorrect libraries to fix in $lib_path".
  else
    echo "Fixed $fixcount incorrect libraries in $lib_path".
  fi

}

# If a sysroots path was passed in, then use it
if [[ $1 ]]; then
  sysroots_root=$(readlink --canonicalize $1)
fi

check_workspace

# Fix broken library symbolic links
fix_broken_libs "usr/lib"
fix_broken_libs "lib"

# Fix library symlinks that point to incorrect versions of actual libraries
fix_incorrect_libs "usr/lib"
fix_incorrect_libs "lib"

# Create non-versioned symbolic links for certain libraries that do not have them
fix_missing_links

echo "Snapdragon Flight SDK fix complete."
