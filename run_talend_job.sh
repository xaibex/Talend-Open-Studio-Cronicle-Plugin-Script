#!/bin/bash

cd `dirname $0`
echo "starting Talend Job $1 with context=$2"

TALENDJOBSCRIPT=$(find . -name $1_run.sh)
if [ -z $TALENDJOBSCRIPT ]
then
  echo "Error: Talend Job not found $1"
  echo '{ "complete": 1, "code": 1, "description": "Error: Talend Job not found '$1'" }'
  exit 1
fi
echo "Jobscript="$TALENDJOBSCRIPT


chmod a+x $TALENDJOBSCRIPT
if [ $? -eq 0 ]
then
  echo "Successfully set executable permissions (chmod a+x) on $TALENDJOBSCRIPT"
else
  echo "Error: Could not set executable permissions (chmod a+x) on $TALENDJOBSCRIPT"
  echo '{ "complete": 1, "code": 2, "description": "Error: Could not set executable permissions (chmod a+x) on '$TALENDJOBSCRIPT'" }'
  exit 2
fi


sedreturn=$(sed -i 's/--context=.*/--context='$2'/g' $TALENDJOBSCRIPT)
grep $2 -q $TALENDJOBSCRIPT
if [ $? -eq 0 ]
then
  echo "Context $2 set in $TALENDJOBSCRIPT"
else
  echo "Error: Could not set context $2 in $TALENDJOBSCRIPT"
  echo '{ "complete": 1, "code": 3, "description": "Error: Could not set context '$2' in '$TALENDJOBSCRIPT'" }'
  exit 3
fi

scriptreturn=$($TALENDJOBSCRIPT)
errorcode=$?

if [ $errorcode -eq 0 ]
then
  greperror=$(grep "\[ERROR\]" <<< "$scriptreturn")
  if [ $? -eq 0 ]
  then
    errorcode=4
  fi

  greperror=$(grep "\[FATAL\]" <<< "$scriptreturn")
  if [ $? -eq 0 ]
  then
    errorcode=5
  fi
fi

if [ $errorcode -eq 0 ]
then
  echo "Talend Job $TALENDJOBSCRIPT executed successefuly..."
  echo  "$scriptreturn"
  echo '{ "complete": 1 }'
  #If completed exit with code 0
  exit 0
else
  echo "Error: executing $TALENDJOBSCRIPT"
  echo  "$scriptreturn"
  if [ -z $greperror]
  then 
    echo '{ "complete": 1, "code": '$errorcode', "description": "Error executing '$TALENDJOBSCRIPT'" }'
  else
    echo '{ "complete": 1, "code": '$errorcode', "description": "'$greperror'" }'
  fi
  exit $errorcode
fi








