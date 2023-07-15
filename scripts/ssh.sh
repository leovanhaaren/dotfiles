#!/bin/bash

###########
### SSH ###
###########
output=$(s -al ~/.ssh)

if [[ -n "$output" ]]; then
    echo "SSH key found, skipping creation."
else
    echo "Creating an SSH key for you..."
    ssh-keygen -t rsa
    pbcopy < ~/.ssh/id_rsa.pub

    echo "Please add this public key to Github \n"
    echo "https://github.com/account/ssh \n"
    read -p "Press [Enter] key after this..."
fi