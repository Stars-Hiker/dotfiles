#!/bin/env bash

# Function to append "M" to a variable
addM() {
    local var="$1"
    local size="${!var}M"  # Append "M" to the value
    eval "$var=\$size"  # Update the variable with the new value
}

# Show available disks on the computer
showDisk() {
    echo "--- YOUR DISKS ---"
    echo
    sudo fdisk -l | grep "Disk" | grep "/dev/"
    chooseDisk
}

# Prompt the user to enter the disk name
chooseDisk() {
    echo
    echo "--- ENTER YOUR DISK NAME (e.g., sda, nvme0n1) ---"
    echo
    read -r diskName
    echo
    
    checkDisk
}

# Check if the entered disk name is valid
checkDisk() {
    local disk_output
    disk_output=$(fdisk -l | grep "Disk" | grep "/dev/" | awk '{ print $2 }' | sed 's|/dev/||; s|:||')

    # Convert the output to an array
    IFS=$'\n' read -r -d '' -a disk_array <<< "$disk_output"

    # Loop through the array
    for disk in "${disk_array[@]}"; do
        if [ "$disk" = "$diskName" ]; then
            echo "-- MATCH FOUND: $disk --"
            # Get the disk size
            diskSize=$(lsblk -b | grep -w "$diskName" | awk '{ print $4 }')
            diskSize=$(echo "scale=2; $diskSize / (1024^3)" | bc)  # Convert size from bytes to gigabytes
            part
            return
        fi    
    done

    echo "-- NOT A VALID DISK! TRY AGAIN --"
    showDisk
}

# Function to check if a string is an integer
is_integer() {
    [[ $1 =~ ^[0-9]+$ ]]
}

# Prompt for a valid number
promptForNumber() {
    local promptMessage=$1
    local variableName=$2

    while true; do
        echo "$promptMessage"
        read -r number
        if [ -z "$number" ]; then
            echo "-- EMPTY ENTRIES ARE NOT ALLOWED --"
        elif ! is_integer "$number"; then
            echo "-- ONLY INTEGERS ARE ALLOWED --"
        elif [ "$number" -eq 0 ]; then
            echo "-- 0 IS NOT A VALID ENTRY --"
        else
            eval "$variableName=$number"
            return
        fi
    done
}

# Partition the disk based on user input
part() {
    echo "--- DISK $diskName IS $diskSize GB ---"
    echo
    promptForNumber "-- How many OS would you like to install? --" osNumber
    bootSize1=$((550)) # Boot size in MB
    bootSize=$(echo "$osNumber * $bootSize1" | bc) # Total boot size in MB
    echo
    echo "-- BOOT SIZE WILL BE $bootSize MB --"
    echo
    promptForNumber "-- CHOOSE SIZE FOR THE MAIN OS IN GIGABYTES --" mainOsSize
    mainOsMb=$(echo "$mainOsSize * 1024" | bc) # Convert to MB
    restOsSize=$(echo "($diskSize * 1024) - $mainOsMb - $bootSize" | bc) # Remaining size in MB
    echo
    echo "-- STILL $restOsSize MB TO BE USED --"
    echo
    partitionSize
}

# Calculate partition sizes
partitionSize() {
    restOsNumber=$((osNumber - 1))
    partSize=$(echo "scale=2; ($restOsSize / $restOsNumber) - 1" | bc) # Size of each remaining partition in MB
    totalPartitionNumber=$((osNumber + 1))
    echo
    echo "-- $totalPartitionNumber PARTITIONS WILL BE MADE --"
    echo
    echo "-- 1 BOOT on '${diskName}1' WILL BE + $bootSize MB --"
    echo "-- 1 MAIN OS on '${diskName}2' WILL BE + $mainOsSize GB --"
    echo "-- $restOsNumber OTHER PARTITIONS OF + $partSize MB WILL BE MADE --"
    echo
    addM bootSize
    addM mainOsMb
    addM partSize
    buildPart
}

# Build partition command sequence
buildPart() {
    gdisk_partition_procedure=("o" "y" "n" " " " " "+$bootSize" "ef00" "n" " " " " "+$mainOsMb" "8300")
    restOsNumber=$((osNumber - 1))
    for ((i = 1; i <= restOsNumber; i++)); do
        gdisk_partition_procedure+=("n" " " " " "+$partSize" "8300")
    done
    endArray=("w" "y")
    gdisk_partition_procedure+=("${endArray[@]}")
    jobDone
}

# Execute the partitioning
jobDone() {
    gdisk /dev/$diskName <<EOF
$(printf "%s\n" "${gdisk_partition_procedure[@]}")
EOF
}

# Start the script by showing disks
#showDisk
