#!/bin/env bash

#humanSize() {
#    hr=$(echo "scale=5; $1" | bc)
#    echo $hr
#}

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
    diskSize=$(echo "scale=20; $diskSize / (1024^3)" | bc)  # Convert size from bytes to gigabytes
    part
}

part() {
    #fdiskSize=$(humanSize $diskSize)
    echo "--- DISK $diskName IS $diskSize G ---"
    echo
    echo "-- How many OS would you like to install? --"
    echo
    read -r osNumber
    bootSize1=$((1024 * 1024 * 550))
    bootSizeInGB=$(echo "scale=20; $bootSize1 / (1024^3)" | bc)
    bootSize=$(echo "scale=20; $osNumber * $bootSizeInGB" | bc)
    echo
    #fbootSize=$(humanSize $bootSize)
    echo "-- BOOT SIZE WILL BE $bootSize G --"
    echo
    echo "-- CHOOSE SIZE FOR THE MAIN OS IN GIGABYTES --"
    read -r mainOsSize
    #mainSizeByte=$(( 1024 * 1024 * 1024 * $mainOsSize ))
    #mainSizeGB=$( echo "scale=20; $mainSizeByte / (1024^3)" )
    echo
    restOsSize=$(echo "scale=20; $diskSize - $mainOsSize - $bootSize" | bc)
    echo
    #frestOsSize=$(humanSize $restOsSize)
    echo "-- STILL $restOsSize G TO BE USED --"
    echo
    partitionSize
}

partitionSize() {
    restOsNumber=$((osNumber - 1))
    partsize=$(echo "scale=20; $restOsSize / $restOsNumber" | bc)
    #fpartsize=$(humanSize $partsize)
    echo "-- THE OTHER PARTITION WILL BE $partsize G --"
    totalPartitionNumber=$((osNumber + 1))
    echo
    echo "-- $totalPartitionNumber PARTITIONS WILL BE MADE --"
    echo "-- BOOT sda1 WILL BE $bootSize G --"
    echo "-- MAIN PARTITION sda2 WILL BE $mainOsSize G --"
    echo "-- $restOsNumber OTHER PARTITIONS OF $partsize G WILL BE MADE --"
    echo
}

showDisk
