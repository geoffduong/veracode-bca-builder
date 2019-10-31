#!/bin/bash

# GET XCODE PROJECT (OR WORKSPACE) PATH, SCHEME, AND OUTPUT LOCATION
PROJECT_PATH="$1"
SCHEME=$2
OUTPUT_LOCATION="$3"
IS_RELEASE="$4"

# DETERME THE XCODE TYPE
if [ ${PROJECT_PATH:(-9)} = "workspace" ]
then 
    XCODE_TYPE="workspace"
    PROJECT=$(basename "$PROJECT_PATH" .xcworkspace)
else
    XCODE_TYPE="project"
    PROJECT=$(basename "$PROJECT_PATH" .xcodeproj)
fi

# CREATE A WORKING TEMP DIRECTORY AND SWITCH TO IT
cd $TMPDIR
WORKING_DIR=$(mktemp -d veracode_bitcode.XXXXXX)
cd $WORKING_DIR

# RUN XCODEBUILD
if [ "${IS_RELEASE}" = "release" ]
then
    echo "Building as Release"
    xcodebuild -configuration Release archive -"${XCODE_TYPE}" "$PROJECT_PATH" -scheme "$SCHEME" -archivePath "$PROJECT" -destination generic/platform=iOS DEBUG_INFORMATION_FORMAT=dwarf-with-dsym ENABLE_BITCODE=YES
else
    echo "Building as Debug"
    xcodebuild archive -"${XCODE_TYPE}" "$PROJECT_PATH" -scheme "$SCHEME" -archivePath "$PROJECT" -destination generic/platform=iOS DEBUG_INFORMATION_FORMAT=dwarf-with-dsym ENABLE_BITCODE=YES
fi

# MOVE APPLICATIONS DIRECTORY OUT OF PRODUCTS AND UP TO PARENT
echo ${PROJECT}
mv ${PROJECT}.xcarchive/Products/Applications/ ${PROJECT}.xcarchive/Payload/

# REMOVE THE PRODUCTS DIRECTORY
rmdir ${PROJECT}.xcarchive/Products/

# ZIP ALL FILES IN XCODE ARCHIVE
cd ${PROJECT}.xcarchive
zip -r ${OUTPUT_LOCATION}/${SCHEME}.bca $(ls)
