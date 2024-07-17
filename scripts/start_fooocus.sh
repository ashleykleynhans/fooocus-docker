#!/usr/bin/env bash

ARGS=("$@" --listen --port 3001)

export PYTHONUNBUFFERED=1
export HF_HOME="/workspace"
source /venv/bin/activate
cd /workspace/Fooocus

if [[ ${PRESET} ]]
then
    echo "Starting Fooocus using preset: ${PRESET}"
    nohup python3 entry_with_update.py --listen --port 3001 --preset ${PRESET} > /workspace/logs/fooocus.log 2>&1 &
else
    echo "Starting Fooocus using defaults"
    nohup python3 entry_with_update.py "${ARGS[@]}" > /workspace/logs/fooocus.log 2>&1 &
fi

echo "Fooocus started"
echo "Log file: /workspace/logs/fooocus.log"
deactivate
