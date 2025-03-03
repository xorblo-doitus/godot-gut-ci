#!/bin/bash
set -e

GODOT_VERSION=$1
GUT_PARAMS=$2
PROJECT_PATH=$3
EDITOR_RUNTIME=$4
EDITOR_RUNS=$5
GODOT_BIN=/usr/local/bin/godot

# Download Godot
GODOT_PARAMS=
is_version_4=$( [[ $GODOT_VERSION == 4* ]] && echo "true" || echo "false" )

if [[ $is_version_4 == "true" ]]; then
  echo "Downloading Godot4"

  wget https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip

  # Unzip it
  unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip
  mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 $GODOT_BIN
  GODOT_PARAMS="--headless"
else
  echo "Downloading Godot3"

  wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip

  # Unzip it
  unzip Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip
  mv Godot_v${GODOT_VERSION}-stable_linux_headless.64 $GODOT_BIN
fi

# Run the tests
if [[ -n $PROJECT_PATH ]]; then
  cd $PROJECT_PATH
fi

if [ $is_version_4 == "true" ] && ! test -f ./.godot/global_script_class_cache.cfg ; then
  echo Starting editor to build .godot/global_script_class_cache.cfg

  for i in `seq 1 $EDITOR_RUNS`
  do
    $GODOT_BIN -e --headless --path $PWD | tee $TEMP_OUTPUT & godotpid=$!

    # TEMP_OUTPUT=/tmp/godot.log
    
    # $GODOT_BIN -e --headless --path $PWD | tee $TEMP_OUTPUT & godotpid=$!

    # FILE_COUNT=$(find ./.godot -type f | wc -l)
    # LAST_OUTPUT=$(cat $TEMP_OUTPUT | wc -l)
    # while [[ ! ( (-f "./.godot/global_script_class_cache.cfg") && ($FILE_COUNT==$(find ./.godot -type f | wc -l)) && ($(cat $TEMP_OUTPUT | wc -l)==$LAST_OUTPUT) ) ]]; do
    #   echo Number of files in .godot/: $FILE_COUNT;
    #   echo Number of lines iin output: $LAST_OUTPUT;
    #   FILE_COUNT=$(find ./.godot -type f | wc -l);
    #   LAST_OUTPUT=$(cat $TEMP_OUTPUT)
    #   sleep 7s;
    # done
    # sleep 0.1s
    # kill $godotpid

    sleep $EDITOR_RUNTIME
    kill $godotpid
  done
  echo .godot/global_script_class_cache.cfg created
fi

echo Running GUT tests using params:
echo "  -> $GUT_PARAMS"

TEMP_FILE=/tmp/gut.log
$GODOT_BIN -d -s $GODOT_PARAMS --path $PWD addons/gut/gut_cmdln.gd -gexit $GUT_PARAMS 2>&1 | tee $TEMP_FILE

# Godot always exists with error 0, but we want this action to fail in case of errors
if grep -q "No tests ran" "$TEMP_FILE";
then
  echo "No test ran. Please check your 'gut_params'"
  exit 1
fi

if  ! grep -q "All tests passed" "$TEMP_FILE"
then
  echo "One or more test have failed"
  exit 1
fi

echo "ALL GOOD :) :) :)"

exit 0
