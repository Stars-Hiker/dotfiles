#!/bin/env bash

# Show disk on computer
showDisk() {
    echo "--- YOUR DISKS ---"
    echo
    sudo fdisk -l | grep "Disk" | grep "/dev/"
    chooseDisk
}

chooseDisk() {
    echo
    echo "--- ENTER YOUR DISK NAME ---"
    echo
    read -r diskName
    echo
    # Get the disk size
    diskSize=$(lsblk -b | grep -w "$diskName" | awk '{ print $4 }')
    diskSize=$(echo "scale=2; $diskSize / (1024^3)" | bc)  # Convert size from bytes to gigabytes
    part
}

part() {
    echo "--- DISK $diskName IS $diskSize G ---"
    echo
    echo "-- How many OS would you like to install? --"
    echo
    read -r osNumber
    bootSize=$(echo "scale=4; $osNumber * 0.55" | bc)
    echo
    echo "-- BOOT SIZE WILL BE $bootSize G --"
    echo
    echo "-- CHOOSE SIZE FOR THE MAIN OS IN GIGABYTES --"
    read -r mainOsSize
    echo
    restOsSize=$(echo "scale=4; $diskSize - $mainOsSize - $bootSize" | bc)
    echo
    echo "-- STILL $restOsSize G TO BE USED --"
    echo
    partitionSize
}

partitionSize() {
    restOsNumber=$((osNumber - 1))
    partsize=$(echo "scale=4; $restOsSize / $restOsNumber" | bc)
    echo "-- THE OTHER PARTITION WILL BE $partsize G --"
    totalPartitionNumber=$((osNumber + 1))
    echo
    echo "-- $totalPartitionNumber PARTITIONS WILL BE MADE --"
    echo "-- BOOT sda1 WILL BE $bootSize G --"
    echo "-- MAIN PARTITION WILL BE $mainOsSize G --"
    echo "-- $restOsNumber OTHER PARTITIONS OF $partsize G WILL BE MADE --"
    echo
}

showDisk
