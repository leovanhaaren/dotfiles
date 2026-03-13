#!/bin/bash

###########
### SSH ###
###########
# output=$(s -al ~/.ssh)

# if [[ -n "$output" ]]; then
#     echo "SSH key found, skipping creation."
# else
#     echo "Creating an SSH key for you..."
#     ssh-keygen -t rsa
#     pbcopy < ~/.ssh/id_rsa.pub

#     echo "Please add this public key to Github \n"
#     echo "https://github.com/account/ssh \n"
#     read -p "Press [Enter] key after this..."
# fi


# Instead of using the above code, you can use 1pass to generate a new SSH key and add it to your GitHub account.
# 1. Open 1Password and navigate to the "SSH Keys" section.
# 2. Click on "Generate New SSH Key" and follow the prompts to create a new key.
# 3. Once the key is generated, copy the public key to your clipboard.
# 4. Open your terminal and run the following command to add the key to your SSH agent:
SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ssh-add -l