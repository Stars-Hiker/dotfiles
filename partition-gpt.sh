#!/bin/env bash

# Function to append "G" to a variable
addG() {
    local var="$1"
    local size="${!var}G"  # Append "G" to the value
    eval "$var=\$size"  # Update the variable with the new value
}

# -- 1 -- Show disk on computer
showDisk() {
    echo "--- YOUR DISKS ---"
    echo
    sudo fdisk -l | grep "Disk" | grep "/dev/"
    chooseDisk
}

# -- 2 --
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

# -- 3 --
part() {
    echo "--- DISK $diskName IS $diskSize G ---"
    echo
    echo "-- How many OS would you like to install? --"
    echo
    read -r osNumber
    bootSize1=$((1024 * 1024 * 550))
    bootSizeInGB=$(echo "scale=20; $bootSize1 / (1024^3)" | bc)
    bootSize=$(echo "scale=20; $osNumber * $bootSizeInGB" | bc)
    echo
    echo "-- BOOT SIZE WILL BE $bootSize G --"
    echo
    echo "-- CHOOSE SIZE FOR THE MAIN OS IN GIGABYTES --"
    read -r mainOsSize
    echo
    restOsSize=$(echo "scale=20; $diskSize - $mainOsSize - $bootSize" | bc)
    echo
    echo "-- STILL $restOsSize G TO BE USED --"
    echo
    partitionSize
}


# -- 4 --
partitionSize() {
    restOsNumber=$((osNumber - 1))
    partsize=$(echo "scale=20; $restOsSize / $restOsNumber" | bc)
    echo "-- THE OTHER PARTITION WILL BE $partsize G --"
    totalPartitionNumber=$((osNumber + 1))
    echo
    echo "-- $totalPartitionNumber PARTITIONS WILL BE MADE --"
    echo
    echo "-- 1 BOOT on 'sda1' WILL BE + $bootSize G --"
    echo "-- 1 MAIN OS on 'sda2' WILL BE + $mainOsSize G --"
    echo "-- $restOsNumber OTHER PARTITIONS OF + $partsize G WILL BE MADE --"
    echo
    addG bootSize
    addG mainOsSize
    addG partsize
    gdisk_patition_Procedure=("o" "y" "y" "n" " " " " "+$bootSize" " " "n" " " " " "+$mainOsSize" " ")
    buildPart
}



# -- load under 5 --
unsetel() {
    unset 'gdisk_patition_Procedure[$1]'
    # Rebuild the array to remove the gap
    gdisk_patition_Procedure=("${gdisk_patition_Procedure[@]}")
}



# -- 5 --
buildPart() {
    addOsArray=("n" " " " " "+$partsize" " ")
    echo "-- CREATE A NEW GPT TABLE ? (y/n) --"
    read -r gtable
    echo "____________________"
    if [ "$gtable" != "y" ]; then
        unsetel 0
        unsetel 0
        unsetel 0
    fi
    i=0
    while [ $i -lt $restOsNumber ];do
        gdisk_patition_Procedure=("${gdisk_patition_Procedure[@]}" "${addOsArray[@]}")
        ((i++))
    done
    endArray=("w" "y")
    gdisk_patition_Procedure=("${gdisk_patition_Procedure[@]}" "${endArray[@]}")
    printArray
}

# -- 6 --
printArray() {
    for element in "${gdisk_patition_Procedure[@]}"; do
        echo $element
    done
}

showDisk
