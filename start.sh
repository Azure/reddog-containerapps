mkdir -p outputs

# get params from config.json file
export CONFIG="$(cat config.json | jq -r .)"

# set initial variables
export LOCATION="$(echo $CONFIG | jq -r '.location')"
export USERNAME="$(echo $CONFIG | jq -r '.username')"
export SUFFIX=$RANDOM
# export RG=$PREFIX-cont-app-reddog-$SUFFIX
export RG=reddog-cont-app-$SUFFIX
export LOGFILE_NAME="./outputs/${RG}.log"

./walk-the-dog.sh $RG $LOCATION $SUFFIX $USERNAME 2>&1 | tee -a $LOGFILE_NAME