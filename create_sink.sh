#!/usr/bin/env bash

# Enhanced Virtual Microphone Creator with Default Sink Capture
# Creates a virtual MIC (source) that mixes selected inputs
# Requires: pactl, fzf, awk

VIRTUAL_MIC="virtual_mic"
VIRTUAL_SINK="virtual_mic_sink"  # Hidden sink for processing
LOADED_MODULES=()
CONFIRM_EXIT=0

cleanup() {
  if (( CONFIRM_EXIT < 1 )); then
    echo -e "\nPress Ctrl+C again to confirm exit, any other key to continue..."
    CONFIRM_EXIT=1
    return
  fi

  echo -e "\nCleaning up virtual microphone..."
  # Unload in reverse order
  for (( idx=${#LOADED_MODULES[@]}-1 ; idx>=0 ; idx-- )) ; do
    pactl unload-module "${LOADED_MODULES[idx]}"
  done
  pactl unload-module module-null-sink 2>/dev/null
  pactl unload-module module-remap-source 2>/dev/null
  echo "Virtual microphone removed"
  exit 0
}

trap cleanup SIGINT

select_device() {
  local type=$1  # "source" or "sink"
  local prompt=$2
  local exclude_monitor=${3:-0}
  
  local devices
  if (( exclude_monitor )); then
    devices=$(pactl list short "${type}s" | grep -v '\.monitor' | awk -F'\t' '{print $1,$2}')
  else
    devices=$(pactl list short "${type}s" | awk -F'\t' '{print $1,$2}')
  fi

  echo "$devices" | fzf --prompt="$prompt > " --height=40% --reverse | awk '{print $1}'
}

create_virtual_mic() {
  # Create processing sink
  pactl load-module module-null-sink \
    sink_name="$VIRTUAL_SINK" \
    sink_properties=device.description="VIRTUAL_MIC_PROCESSING"
  
  # Create actual virtual mic that points to the sink
  pactl load-module module-remap-source \
    source_name="$VIRTUAL_MIC" \
    master="$VIRTUAL_SINK.monitor" \
    source_properties=device.description="Virtual_Microphone"
}

add_microphone() {
  local mic_id=$(select_device "source" "Select microphone to add" 1)
  [[ -z "$mic_id" ]] && return
  
  local mod=$(pactl load-module module-loopback \
    source="$mic_id" \
    sink="$VIRTUAL_SINK" \
    latency_msec=20)
  
  LOADED_MODULES+=("$mod")
  echo "Added microphone (ID: $mic_id)"
}

add_application_audio() {
  clear
  echo -e "Add Application Audio Source\n"
  echo "1. Select Specific Application Output"
  echo "2. Capture Default Output Sink (Dynamic)"
  echo "3. Back to Main Menu"
  
  read -rp "Select option (1-3): " choice
  case $choice in
    1)
      local sink_id=$(select_device "sink" "Select application audio to capture" 1)
      [[ -z "$sink_id" ]] && return
      
      local mod=$(pactl load-module module-loopback \
        source="$sink_id.monitor" \
        sink="$VIRTUAL_SINK" \
        latency_msec=20)
      
      LOADED_MODULES+=("$mod")
      echo "Added application audio (ID: $sink_id)"
      ;;
    2)
      local default_sink=$(pactl get-default-sink)
      echo -e "\nCapturing DEFAULT output sink: $default_sink"
      echo "Note: This will follow default sink changes"
      
      local mod=$(pactl load-module module-loopback \
        source="$default_sink.monitor" \
        sink="$VIRTUAL_SINK" \
        latency_msec=20)
      
      LOADED_MODULES+=("$mod")
      echo "Added default sink capture"
      ;;
    3) return ;;
    *) echo "Invalid option"; sleep 1 ;;
  esac
}

show_status() {
  clear
  echo -e "Virtual Microphone Status\n"
  echo "Virtual Mic Name: $VIRTUAL_MIC"
  echo "Available as input source in applications"
  echo -e "\nCurrent Inputs:"
  
  pactl list short modules | grep -E "loopback|remap-source|null-sink" | while read -r line; do
    if [[ "$line" == *"source_name=$VIRTUAL_MIC"* ]]; then
      echo "* Virtual Microphone Output"
    elif [[ "$line" == *"sink_name=$VIRTUAL_SINK"* ]]; then
      echo "* Processing Sink (Hidden)"
    elif [[ "$line" == *".monitor"* ]]; then
      if [[ "$line" == *"$(pactl get-default-sink).monitor"* ]]; then
        echo "* DEFAULT OUTPUT SINK: $(echo "$line" | awk '{print $4}')"
      else
        echo "* Application Audio: $(echo "$line" | awk '{print $4}')"
      fi
    else
      echo "* Microphone: $(echo "$line" | awk '{print $4}')"
    fi
  done
  
  read -rp $'\nPress Enter to continue...'
}

main_menu() {
  while true; do
    clear
    echo -e "Virtual Microphone Mixer\n"
    echo "1. Add Physical Microphone"
    echo "2. Add Application Audio"
    echo "3. Show Current Status"
    echo "4. Remove Last Added Input"
    echo "5. Exit"
    echo -e "\nUse '$VIRTUAL_MIC' as your microphone in apps"
    
    read -rp "Select option (1-5): " choice
    case $choice in
      1) add_microphone; sleep 1 ;;
      2) add_application_audio; sleep 1 ;;
      3) show_status ;;
      4)
        if (( ${#LOADED_MODULES[@]} > 0 )); then
          pactl unload-module "${LOADED_MODULES[-1]}"
          unset 'LOADED_MODULES[-1]'
          echo "Removed last input"
          sleep 1
        else
          echo "No inputs to remove"
          sleep 1
        fi
        ;;
      5) cleanup ;;
      *) echo "Invalid option"; sleep 1 ;;
    esac
  done
}

# Initialize
create_virtual_mic
main_menu