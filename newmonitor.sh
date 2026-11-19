
#!/bin/bash

PID=$1
INTERVAL=${2:-1}
LOG_FILE=${3:-"process_${PID}.log"}

if [ -z "$PID" ]; then
    echo "Usage: $0 <PID> [interval] [log_file]"
    exit 1
fi

if ! kill -0 "$PID" 2>/dev/null; then
    echo "PID $PID does not exist."
    exit 1
fi

PREVIOUS=""

echo "Monitoring PID: $PID"
echo "Interval: ${INTERVAL}s"
echo "Log: $LOG_FILE"

while kill -0 "$PID" 2>/dev/null; do

    # Get process data using top
    CURRENT=$(top -b -n 1 -p "$PID" 2>/dev/null | \
        awk -v pid="$PID" '$1 == pid {
            printf "%s %s %s %s %s %s",
            $9, $10, $6, $5, $20, $8
        }')

    if [ -z "$CURRENT" ]; then
        sleep "$INTERVAL"
        continue
    fi

    # Only log when resource values change
    if [ "$CURRENT" != "$PREVIOUS" ]; then

        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')

        read CPU MEM RES VIRT THREADS STATUS <<< "$CURRENT"

        echo "$TIMESTAMP | PID=$PID | CPU=${CPU}% | MEM=${MEM}% | RES=${RES} | VIRT=${VIRT} | THREADS=$THREADS | STATUS=$STATUS" >> "$LOG_FILE"

        PREVIOUS="$CURRENT"
    fi

    sleep "$INTERVAL"

done

echo "$(date '+%Y-%m-%d %H:%M:%S') | PID=$PID terminated" >> "$LOG_FILE"

echo "Monitoring stopped."
