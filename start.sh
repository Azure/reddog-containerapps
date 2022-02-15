mkdir -p outputs

# get params from config.json file
export CONFIG="$(cat config.json | jq -r .)"

# set initial variables
export LOCATION="$(echo $CONFIG | jq -r '.location')"
export PREFIX="$(echo $CONFIG | jq -r '.prefix')"
export SUFFIX=$RANDOM
export RG=$PREFIX-cont-app-reddog-$SUFFIX
export LOGFILE_NAME="./outputs/${RG}.log"

./walk-the-dog.sh $RG $LOCATION $SUFFIX 2>&1 | tee -a $LOGFILE_NAME