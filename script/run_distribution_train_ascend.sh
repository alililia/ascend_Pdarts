#!/bin/bash
# Copyright 2022 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================
# an simple tutorial as follows, more parameters can be setting
if [ $# != 3 ]
then
    echo "Usage: bash run_distribution_train_ascend.sh [RANK_TABLE_FILE] [CIFAR10_DATA_PATH] [OUTPUT_PATH]"
exit 1
fi

if [ ! -f $1 ]
then
    echo "error: RANK_TABLE_FILE=$1 is not a file"
exit 1
fi

ulimit -u unlimited
export DEVICE_NUM=8
export RANK_SIZE=8
RANK_TABLE_FILE=$(realpath $1)
export RANK_TABLE_FILE
CIFAR10_DATA_PATH=$2
OUTPUT_PATH=$3
echo "RANK_TABLE_FILE=${RANK_TABLE_FILE}"

rank_start=0
for((i=0; i<${DEVICE_NUM}; i++))
do
    export DEVICE_ID=$i
    export RANK_ID=$((rank_start + i))
    rm -rf ./train_parallel$i
    mkdir ./train_parallel$i
    cp -r ./src ./train_parallel$i
    cp ./train.py ./train_parallel$i
    echo "start training for rank $RANK_ID, device $DEVICE_ID"
    cd ./train_parallel$i ||exit
    env > env.log
    python train.py --data_url $CIFAR10_DATA_PATH --train_url $OUTPUT_PATH --optimizer SGD \
                --load_weight None --no_top False --learning_rate 0.075 --batch_size 32 > log 2>&1 &
    echo "start training for rank $RANK_ID, device $DEVICE_ID has started"
    cd ..
done