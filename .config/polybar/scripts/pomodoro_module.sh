#!/bin/bash

# Pomodoro Module Script
# For independent Polybar modules (work, short-break, long-break, cycle-count, workout).

MODULE_MODE="$1"
STATE_FILE="/tmp/polybar_pomodoro_${MODULE_MODE}_state"
ANIM_STATE_FILE="/tmp/polybar_pomodoro_${MODULE_MODE}_anim_state"
GLOBAL_CYCLE_COUNT_FILE="/tmp/polybar_pomodoro_global_cycle_count"
CUSTOM_WORK_TIME_FILE="/tmp/polybar_pomodoro_custom_work_time"

# Pomodoro Work Times in seconds (25min, 30min, 45min, 60min)
# You can adjust these values and add more if you wish
declare -a WORK_TIMES=(1500 1800 2700 3600)

case "$MODULE_MODE" in
    "work")        DEFAULT_TIME=1500; LABEL_PREFIX=" Work";       STATIC_ICON="";;
    "short-break") DEFAULT_TIME=300;  LABEL_PREFIX=" S.Break";   STATIC_ICON="";;
    "long-break")  DEFAULT_TIME=900;  LABEL_PREFIX=" L.Break";   STATIC_ICON="";;
    "workout")     DEFAULT_TIME=180;  LABEL_PREFIX=" Workout";    STATIC_ICON="";; # 3 minutes (180s) fixed
    "cycle-count") DEFAULT_TIME=0;    LABEL_PREFIX=" sCycles";    STATIC_ICON="";;
    *)             echo "Error: Invalid module mode." >&2; exit 1;;
esac

# Nerd Fonts Icons (using direct Unicode characters)
ICON_HOURGLASS_START=""
ICON_HOURGLASS_HALF=""
ICON_HOURGLASS_END=""
ICON_PAUSE=""
ICON_PLAY=""
ICON_STOP=""

# Animation icons for rotation (reversed for progression) 
ANIMATION_ICONS=(
    "$ICON_HOURGLASS_START"
    "$ICON_HOURGLASS_HALF"
    "$ICON_HOURGLASS_END"
)
NUM_ANIM_ICONS=${#ANIMATION_ICONS[@]}

get_module_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "stopped $DEFAULT_TIME" > "$STATE_FILE"
    fi
    cat "$STATE_FILE"
}

update_module_state() {
    echo "$1 $2" > "$STATE_FILE"
}

get_anim_state() {
    if [[ ! -f "$ANIM_STATE_FILE" ]]; then
        echo "0" > "$ANIM_STATE_FILE"
    fi
    cat "$ANIM_STATE_FILE"
}

update_anim_state() {
    echo "$1" > "$ANIM_STATE_FILE"
}

get_global_cycle_count() {
    if [[ ! -f "$GLOBAL_CYCLE_COUNT_FILE" ]]; then
        echo "0" > "$GLOBAL_CYCLE_COUNT_FILE"
    fi
    cat "$GLOBAL_CYCLE_COUNT_FILE"
}

update_global_cycle_count() {
    echo "$1" > "$GLOBAL_CYCLE_COUNT_FILE"
}

# Functions for custom work time (used by 'work' module)
get_custom_work_time() {
    if [[ ! -f "$CUSTOM_WORK_TIME_FILE" ]]; then
        echo "${WORK_TIMES[0]}" > "$CUSTOM_WORK_TIME_FILE" # Default to first time
    fi
    cat "$CUSTOM_WORK_TIME_FILE"
}

update_custom_work_time() {
    echo "$1" > "$CUSTOM_WORK_TIME_FILE"
}

# Re-evaluate DEFAULT_TIME for "work" mode based on custom setting
if [[ "$MODULE_MODE" == "work" ]]; then
    DEFAULT_TIME=$(get_custom_work_time)
fi

# Read current state. Adjust TIME_LEFT for 'work' and 'custom' if stopped,
# to reflect the default or accumulated time.
read CURRENT_STATUS STORED_TIME_LEFT < <(get_module_state)

if [[ "$MODULE_MODE" == "work" && "$CURRENT_STATUS" == "stopped" ]]; then
    TIME_LEFT="$DEFAULT_TIME"
elif [[ "$CURRENT_STATUS" == "stopped" ]]; then # For any other module, if stopped, reset to its DEFAULT_TIME
    TIME_LEFT="$DEFAULT_TIME"
else
    TIME_LEFT="$STORED_TIME_LEFT"
fi

CURRENT_ANIM_INDEX=$(get_anim_state)
GLOBAL_CYCLE_COUNT=$(get_global_cycle_count)

get_current_animated_icon() {
    local index=$1
    echo "${ANIMATION_ICONS[$index]}"
}

case "$2" in
    "toggle_play_pause")
        if [[ "$MODULE_MODE" == "cycle-count" ]]; then
            exit 0
        fi

        if [[ "$CURRENT_STATUS" == "running" ]]; then
            update_module_state "paused" "$TIME_LEFT"
            notify-send "${LABEL_PREFIX} Pomodoro" "Paused at ${TIME_LEFT}s."
        elif [[ "$CURRENT_STATUS" == "paused" ]]; then
            update_module_state "running" "$TIME_LEFT"
            notify-send "${LABEL_PREFIX} Pomodoro" "Resumed."
        else
            update_module_state "running" "$TIME_LEFT"
            notify-send "${LABEL_PREFIX} Pomodoro" "Started."
        fi
        update_anim_state "0"
        exit 0
        ;;
    "reset")
        if [[ "$MODULE_MODE" == "cycle-count" ]]; then
            update_global_cycle_count "0"
            notify-send "Pomodoro" "All cycles reset."
        else
            update_module_state "stopped" "$DEFAULT_TIME"
            notify-send "${LABEL_PREFIX} Pomodoro" "Reset."
        fi
        update_anim_state "0"
        exit 0
        ;;
    "change_time") # For 'work' module to change its default time
        if [[ "$MODULE_MODE" == "work" ]]; then
            CURRENT_TIME=$(get_custom_work_time)
            NEXT_INDEX=-1
            for i in "${!WORK_TIMES[@]}"; do
                if [[ "${WORK_TIMES[$i]}" -eq "$CURRENT_TIME" ]]; then
                    NEXT_INDEX=$(( (i + 1) % ${#WORK_TIMES[@]} ))
                    break
                fi
            done

            NEW_TIME="${WORK_TIMES[$NEXT_INDEX]}"
            update_custom_work_time "$NEW_TIME"
            # If the work timer is stopped, update its displayed time immediately
            if [[ "$CURRENT_STATUS" == "stopped" ]]; then
                update_module_state "stopped" "$NEW_TIME"
            fi
            notify-send "Pomodoro Work Time" "Changed to $((NEW_TIME / 60)) minutes."
        fi
        exit 0
        ;;
    "add_60_seconds") # NEW: Add 60 seconds to any active timer
        # This action can be applied to 'work', 'short-break', 'long-break', 'workout'
        if [[ "$MODULE_MODE" != "cycle-count" ]]; then
            NEW_TIME_LEFT=$((TIME_LEFT + 60))
            update_module_state "$CURRENT_STATUS" "$NEW_TIME_LEFT"
            notify-send "${LABEL_PREFIX} Timer" "Added 1 minute. Current: $((NEW_TIME_LEFT / 60)) minutes."
            if [[ "$CURRENT_STATUS" == "stopped" ]]; then
                # If stopped, automatically start it when adding time
                update_module_state "running" "$NEW_TIME_LEFT"
                notify-send "${LABEL_PREFIX} Timer" "Started with $((NEW_TIME_LEFT / 60)) minutes."
            fi
        fi
        exit 0
        ;;
esac

# Main timer logic for running modules
if [[ "$MODULE_MODE" != "cycle-count" && "$CURRENT_STATUS" == "running" ]]; then
    TIME_LEFT=$((TIME_LEFT - 1))

    if [[ "$TIME_LEFT" -le 0 ]]; then
        update_module_state "stopped" "$DEFAULT_TIME"
        notify-send "${LABEL_PREFIX} Pomodoro" "Time's up!"
        paplay ~/Audio/Alarm.ogg & # Sound notification

        if [[ "$MODULE_MODE" == "work" ]]; then
            GLOBAL_CYCLE_COUNT=$((GLOBAL_CYCLE_COUNT + 1))
            update_global_cycle_count "$GLOBAL_CYCLE_COUNT"
        fi

        TIME_LEFT="$DEFAULT_TIME"
        CURRENT_STATUS="stopped"
        update_anim_state "0"
    else
        update_module_state "running" "$TIME_LEFT"
    fi

    CURRENT_ANIM_INDEX=$(( (CURRENT_ANIM_INDEX + 1) % NUM_ANIM_ICONS ))
    update_anim_state "$CURRENT_ANIM_INDEX"
fi

MINUTES=$((TIME_LEFT / 60))
SECONDS=$((TIME_LEFT % 60))

# Format minutes and seconds to always be two digits (e.g., "05" instead of "5")
FORMATTED_MINUTES=$(printf "%02d" "$MINUTES")
FORMATTED_SECONDS=$(printf "%02d" "$SECONDS")

DISPLAY_STRING=""
DISPLAY_ICON=""

case "$MODULE_MODE" in
    "work"|"short-break"|"long-break"|"workout")
        case "$CURRENT_STATUS" in
            "running")
                DISPLAY_ICON=$(get_current_animated_icon "$CURRENT_ANIM_INDEX")
                DISPLAY_STRING="$DISPLAY_ICON ${LABEL_PREFIX}: ${FORMATTED_MINUTES}:${FORMATTED_SECONDS}"
                ;;
            "paused")
                DISPLAY_ICON="$ICON_PAUSE"
                DISPLAY_STRING="$DISPLAY_ICON PAUSED ${LABEL_PREFIX}: ${FORMATTED_MINUTES}:${FORMATTED_SECONDS}"
                ;;
            "stopped")
                DISPLAY_ICON="$STATIC_ICON"
                DISPLAY_STRING="$STATIC_ICON ${LABEL_PREFIX}: ${FORMATTED_MINUTES}:${FORMATTED_SECONDS}"
                ;;
            *) # Fallback
                DISPLAY_ICON="$STATIC_ICON"
                DISPLAY_STRING="$STATIC_ICON ${LABEL_PREFIX}: ${FORMATTED_MINUTES}:${FORMATTED_SECONDS}"
                ;;
        esac
        ;;
    "cycle-count")
        DISPLAY_ICON="$STATIC_ICON"
        DISPLAY_STRING="$DISPLAY_ICON Cycles: ${GLOBAL_CYCLE_COUNT}"
        ;;
esac

echo "$DISPLAY_STRING"