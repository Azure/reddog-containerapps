mkdir -p outputs

# set initial variables
#export PREFIX=$USER
export PREFIX='btr'
export SUFFIX=$RANDOM
export RG=$PREFIX-reddog-cont-app-$SUFFIX
export LOCATION='eastus'
export LOGFILE_NAME="./outputs/${RG}.log"

./walk-the-dog.sh $RG $LOCATION $SUFFIX 2>&1 | tee -a $LOGFILE_NAME