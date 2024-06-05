



________________________________________________________________________
#Removing an element by index

#If you know the index of the element you want to remove, you can use the unset command. Here's an example:


# Define the array
my_array=("element1" "element2" "element3" "element4")

# Index of the element to remove
index=1  # This will remove "element2"

# Remove the element
unset 'my_array[index]'

# Rebuild the array to remove the gap
my_array=("${my_array[@]}")

# Print the array
for element in "${my_array[@]}"; do
    echo "$element"
done

#________________________________________________________________________
# Removing an element by value

#If you need to remove an element by its value, you can iterate over the array and construct a new array excluding the element you want to remove. Here's an example:


# Define the array
my_array=("element1" "element2" "element3" "element4")

# Value of the element to remove
value_to_remove="element2"

# Create a new array excluding the element to remove
new_array=()
for element in "${my_array[@]}"; do
    if [[ "$element" != "$value_to_remove" ]]; then
        new_array+=("$element")
    fi
done

# Replace the original array with the new array
my_array=("${new_array[@]}")

# Print the array
for element in "${my_array[@]}"; do
    echo "$element"
done

#________________________________________________________________________
#Adding a single element

#To add a single element to an array, use the following syntax:

# Define the array
my_array=("element1" "element2" "element3")

# Add a new element
my_array+=("element4")

# Print the array
for element in "${my_array[@]}"; do
    echo "$element"
done

#________________________________________________________________________
#Adding multiple elements

#You can also add multiple elements at once by using the same += operator with an array of new elements:

# Define the array
my_array=("element1" "element2" "element3")

# Add multiple new elements
my_array+=("element4" "element5")

# Print the array
for element in "${my_array[@]}"; do
    echo "$element"
done

#________________________________________________________________________
#Adding elements within a function

#If you want to add elements to an array within a function, you can pass the array name and use the += operator inside the function. Here's an example:

# Define the array
my_array=("element1" "element2" "element3")

# Function to add elements to the array
add_elements() {
    local array_name=$1
    shift
    local new_elements=("$@")

    for element in "${new_elements[@]}"; do
        eval "$array_name+=(\"$element\")"
    done
}

# Add elements to the array using the function
add_elements my_array "element4" "element5"

# Print the array
for element in "${my_array[@]}"; do
    echo "$element"
done

#________________________________________________________________________
# Adding an element at a specific index

# Define the array
my_array=("element1" "element2" "element3" "element4")

# Function to add an element at a specific index
add_at_index() {
    local -n array=$1
    local index=$2
    local new_element=$3

    # Split the array into two parts: before and after the index
    local before=("${array[@]:0:index}")
    local after=("${array[@]:index}")

    # Construct the new array with the element inserted
    array=("${before[@]}" "$new_element" "${after[@]}")
}

# Add an element at index 2
add_at_index my_array 2 "new_element"

# Print the array
for element in "${my_array[@]}"; do
    echo "$element"
done
