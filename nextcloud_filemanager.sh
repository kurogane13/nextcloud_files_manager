#!/bin/bash

# ansi_codes: https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124
# Terminal colors
# Define colors for highlighting

red="\033[31m"
red_high_intensity="\033[0;91m"
yellow="\033[33m"
yellow_high_intensity="\e[0;93m"
cyan="\e[4;36m"
cyan_high_intensity="\e[0;96m"
black="\e[0;30m	"
cyan_high_background="\e[0;106m"
blue_high_background="\e[0;104m"
green_high_background="\e[0;102m"
green_highlight="\033[1;32m"  # Green
green_high_intensity="\e[0;92m"
normal="\033[0m"        # Reset to default
reset="\033[0m"

nextcloud_url="nextcloud.com"

set_nextcloud_url() {
    echo
    read -p "Enter the Nextcloud URL: " nextcloud_url
    echo
    echo "Nextcloud URL set to: $nextcloud_url"
    echo
    read -p "Press enter to return to the main menu: " enter
    main_menu
}

show_nextcloud_url() {
    echo
    echo "Current Nextcloud URL: $nextcloud_url"
    echo
    read -p "Press enter to return to the main menu: " enter
    main_menu
}

list_folder_shares() {
    ls -lha
    echo "--------------------------------------------------------------"
	echo -e "Files and folders found with details:"
	echo
	# Loop through each result
	results=$(find "$PWD" -type f -o -type d)
	while IFS= read -r item; do
		if [ -d "$item" ]; then
			# Use du -sh for directories to show only the size of the directory itself
			echo -e "-------------------------------------------------------------------"
			echo -e "Directory: $item"
			du -sh "$item" | awk '{print $1 " " $2}'

		elif [ -f "$item" ]; then
			# Use ls -lha for files to show detailed info
			echo -e "-------------------------------------------------------------------"
			echo -e "File: $item"
			ls -lha "$item"
		fi
	done <<< "$results"
	echo -e "--------------------------------------------------------------"
	read -p "Press enter to get back to the main menu: " enter
	main_menu
}

search_files_and_folders() {
    # Prompt the user for a regular expression
    echo
    read -p "Enter the regular expression to search for files and folders: " regexp

    # Search for files and folders matching the regular expression
    echo
    echo -e "Searching for files and folders matching '$regexp' in $PWD..."
    results=$(find "$PWD" -type f -o -type d | grep -E "$regexp")

    # Check if results were found
    if [ -z "$results" ]; then
        echo
        echo -e "${red_high_intensity}No files or folders found matching the regular expression '$regexp'${reset}."
        echo
        echo -e "--------------------------------------------------------------"
		read -p "Press enter to get back to the main menu: " enter
		main_menu
    else
        echo -e "Files and folders found with details:"
        echo
        # Loop through each result
        while IFS= read -r item; do
            if [ -d "$item" ]; then
                # Use du -sh for directories to show only the size of the directory itself
                echo -e "-------------------------------------------------------------------"
                echo -e "Directory: $item"
                du -sh "$item" | awk '{print $1 " " $2}'

            elif [ -f "$item" ]; then
                # Use ls -lha for files to show detailed info
                echo -e "-------------------------------------------------------------------"
                echo -e "File: $item"
                ls -lha "$item"
            fi
        done <<< "$results"
		echo -e "--------------------------------------------------------------"
		read -p "Press enter to get back to the main menu: " enter
		main_menu
    fi
}

share_link() {

    # Define the file path
    share_link_file="share_link_file.txt"
    echo
    echo -e "Validating if the folder has a share link file..."
	echo
    # Check if the share link file already exists
    if [[ -f "$folder_share/$share_link_file" ]]; then
        share_link=$(cat "$share_link_file")
        echo
        echo -e "Validation OK!. This folder already has a share link file: $share_link_file"
        echo
    else
        # Prompt for the share link URL
        echo
        echo -e "${red_high_intensity}No share link URL file was found for this folder.${reset}"
        echo
        read -p "Provide your share link url, and press enter to proceed: " share_link

        # Create the file and write the share link to it
        echo -e "$share_link" > "$folder_share/$share_link_file"
    fi
	
}

download_content() {
    echo 
    ls -lha
    echo
    echo "---------------------------------------------------------------------"
    
    # Prompt user for input
    read -p "Enter the folder share to download content to without '/' (e.g., nextcloud): " folder_share
    if [[ ! -d $folder_share ]]; then
        echo
        echo -e "${red_high_intensity}$folder_share not found in $PWD.${reset}"
        echo
        read -p "Press enter to provide an existing folder and/or subfolder: " enter
        download_content
    else
        echo
    fi
    echo "You will be downloading content from nextcloud to local folder: $folder_share"
    echo
    echo "All the content will be downloaded in a zip file called nextcloud_download_content.zip with a datetime timestamp."
    echo

    # Validate if the share link file exists in the provided folder and read the link
    share_link_file_path="$folder_share/share_link_file.txt"
    if [[ -f "$share_link_file_path" ]]; then
        share_link=$(cat "$share_link_file_path")
        echo "Validation OK! This folder already has a share link file: $share_link_file_path"
    else
        echo -e "${red_high_intensity}share_link_file.txt not found in $folder_share.${reset}"
        echo
        read -p "Press enter to provide the share link: " share_link
        echo "$share_link" > "$share_link_file_path"
    fi

    echo "------------------------------------------------------------------------------------------"
    echo
    read -p "Press enter to proceed to download content to local share folder: $folder_share: "

    # Clean and prepare the share link URL
    download_url=$(echo "$share_link" | sed -r 's#(/download)+$#/download#')
    datetimestamp=$(date +'%Y-%m-%d_%H-%M-%S')
    zip_filename="nextcloud_download_content_$datetimestamp.zip"
    zip_file="$folder_share/$zip_filename"
    
    # Construct the corrected URL for download
    corrected_url="${download_url}/download/${zip_filename}"
    corrected_url=$(echo "$corrected_url" | sed 's|/public.php/webdav//|/public.php/webdav/|g')
    
    echo
    timestamp=$(date +'%Y-%m-%d_%H:%M:%S')
    echo "Download executed at: $timestamp"
    echo 
    echo "Downloading content from $corrected_url to $zip_file..."
    echo
    
    # Perform the download using curl
    curl -L -v "$corrected_url" -o "$zip_file"
    echo
    timestamp=$(date +'%Y-%m-%d_%H:%M:%S')
    echo "Download ended at: $timestamp"
    echo 

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        echo "--------------------------------------------------------------"
        ls -lha "$zip_file"
        echo
        echo "Unzipping $zip_file..."
        echo
        
        # Unzip the file
        unzip "$zip_file" -d "$folder_share"
        
        # Check if unzip was successful
        if [[ $? -eq 0 ]]; then
            echo
            rm -rf $zip_file
            echo "Listing all files in: $folder_share"
            ls -lha "$folder_share"
            echo "--------------------------------------------------------------"

        else
            echo -e "${red_high_intensity}Unzip failed. The file may be corrupted.${reset}"
            echo
            read -p "Press enter to return to the main menu: " enter
            echo
            main_menu
        fi
    else
        echo -e "${red_high_intensity}Download failed. Please check the share link URL, or your connection.${reset}"
        read -p "Press enter to return to the main menu: " enter
        echo
        main_menu
    fi
    echo
    read -p "Press enter to get back to the main menu: " enter
    main_menu
}


upload_content() {
    # Ask the user if they want to upload a file or a folder
    echo "Do you want to upload a file or a folder?"
    echo
    echo "1) File"
    echo "2) Folder"
    echo "<--- b - Back to Main menu"
    echo
    read -p "Choose option 1, 2 or b to return to main menu: " choice

    if [[ $choice -eq 1 ]]; then
        # Ask for the full path to the file
        echo
        read -p "Enter the full path to the file (Example: My_folder/sub_folder/file.json): " filepath
        filename=$(basename "$filepath")
        
        if [[ ! -f $filepath ]];then
            echo
            echo -e "${red_high_intensity}ERROR: $filepath not found${reset}"
            echo
            read -p "Press enter to return to the main menu: " enter
            echo
            main_menu
            
        else
            echo
            echo "Provided $filepath is valid"
            echo 
            ls -lha $filepath
        fi

        # Define the file path for the share link file
        share_link_file="$(dirname "$filepath")/share_link_upload.txt"

        # Check if the share link file exists
        if [[ ! -f "$share_link_file" ]]; then
            echo
            echo -e "${red_high_intensity}Share link file not found. Please provide the share link.${reset}"
            echo
            read -p "Provide the share link URL, to proceed with the upload of $filepath: " share_link
            echo "$share_link" > "$share_link_file"
        else
            share_link=$(<"$share_link_file")
        fi

        share_id=$(echo "$share_link" | sed -n 's#https://nc.cloudlinux.com/s/\([^/]*\)$#\1#p')
        echo
        echo "-----------------------------------------------------------------------------------------"
        echo
        read -p "Press enter to proceed to the upload of $filepath to Cloudlinx nextcloud share: " enter
        echo

        # Check if the file exists
        if [[ -f "$filepath" ]]; then
            # Zip the file
            temp_zip="${filepath}.zip"
            echo "Compressing $filepath to $temp_zip..."
            zip -j "$temp_zip" "$filepath"
            
            corrected_url="https://nc.cloudlinux.com/public.php/webdav/$folder_share/$filename"
            corrected_url2=$(echo "$corrected_url" | sed 's|/webdav//|/webdav/|g')
            # Perform the upload using curl
			echo
            echo "Uploading $temp_zip to $share_link..."
            echo
            echo
            timestamp=$(date +'%Y-%m-%d_%H:%M:%S')
            echo "Upload executed at: $timestamp"
            echo 
            curl -v -k -T "$temp_zip" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' $corrected_url2
            echo
            timestamp=$(date +'%Y-%m-%d_%H:%M:%S')
            echo "Upload ended at: $timestamp"
            echo 

            if [[ $? -eq 0 ]]; then
                echo
                echo "File $filename uploaded successfully."
                echo
                read -p "Press enter to return to the main menu: " enter
                echo
                main_menu
            else
                echo
                echo -e "${red_high_intensity}Failed to upload file $filename.${reset}"
                echo
                read -p "Press enter to return to the main menu: " enter
                echo
                main_menu
            fi

            # Clean up the temporary zip file
            rm -f "$temp_zip"
        else
            echo
            echo -e "${red_high_intensity}File $filepath does not exist.${reset}"
            echo
            read -p "Press enter to return to the main menu: " enter
            echo
            main_menu
        fi
    elif [[ $choice -eq 2 ]]; then
        # Ask for the full path to the folder
        echo
        read -p "Enter the full path to the folder you want to upload to Nextcloud without the last '/' (Example: /root/My_folder): " folder_share
        foldername=$(basename "$folder_share")
        temp_zip="$folder_share.zip"
        
        if [[ ! -d $folder_share ]];then
            echo
            echo -e "${red_high_intensity}ERROR: Folder share: $folder_share not found${reset}"
            echo
            read -p "Press enter to return to the main menu: " enter
            echo
            main_menu
        else
            echo
            echo "Provided $folder_share is valid"
            echo 
            ls -lha $folder_share
        fi

        # Define the file path for the share link file
        share_link_file="$(dirname "$folder_share")/share_link_upload.txt"

        # Check if the share link file exists
        if [[ ! -f "$share_link_file" ]]; then
            echo
            echo -e "${red_high_intensity}Share link file not found. Please provide the share link.${reset}"
            echo
            read -p "Provide the share link URL to proceed with the upload of $folder_share: " share_link
            echo "$share_link" > "$share_link_file"
        else
            share_link=$(<"$share_link_file")
        fi

        share_id=$(echo "$share_link" | sed -n 's#https://nc.cloudlinux.com/s/\([^/]*\)$#\1#p')
        
        echo "-----------------------------------------------------------------------------------------"
        echo
        read -p "Press enter to proceed to the upload of $folder_share to Cloudlinx nextcloud share: " enter
        echo

        # Check if the folder exists
        if [[ -d "$folder_share" ]]; then
            # Compress the folder using zip
            echo
            echo "Compressing $folder_share to $temp_zip..."
            zip -r "$temp_zip" "$folder_share"

            corrected_url="https://nc.cloudlinux.com/public.php/webdav/$folder_share/$filename"
            corrected_url2=$(echo "$corrected_url" | sed 's|/webdav//|/webdav/|g')
            # Perform the upload using curl
            echo 
            echo "Uploading $temp_zip to $share_link..."
            echo
            timestamp=$(date +'%Y-%m-%d_%H:%M:%S')
            echo "Upload executed at: $timestamp"
            echo
            curl -v -k -T "$temp_zip" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' $corrected_url2
            echo
            timestamp=$(date +'%Y-%m-%d_%H:%M:%S')
            echo "Upload ended at: $timestamp"
            echo 

            if [[ $? -eq 0 ]]; then
                echo
                echo "Folder $foldername uploaded successfully."
                echo
                read -p "Press enter to return to the main menu: " enter
                echo
                main_menu
            else
                echo
                echo -e "${red_high_intensity}Failed to upload folder $foldername.${reset}"
                echo
                read -p "Press enter to return to the main menu: " enter
                echo
                main_menu
            fi

            # Clean up the temporary zip file
            rm -f "$temp_zip"
        else
            echo
            echo -e "${red_high_intensity}Folder $folder_share does not exist.${reset}"
            echo
            read -p "Press enter to return to the main menu: " enter
            echo
            main_menu
        fi
    
    elif [[ $choice == "b" ]]; then
        echo
        read -p "Press Enter to return to the main menu..."
        main_menu
    else
        echo
        echo -e "${red_high_intensity}Invalid choice. Please select 1 for file or 2 for folder, or b, to go back to main menu.${reset}"
        #${red_high_intensity}Invalid option. Please choose a valid option.${reset}
        echo
        read -p "Press Enter to return to the File and Folder menu: "
        echo
        upload_content
    fi
    echo
    read -p "Press Enter to return to the main menu..."
    main_menu
}


# Array of options
options=(
"####################### *** FILE SHARES MANAGER *** ###########################"
"                                                                     "
"                    Today is:                                        "
"_____________________________________________________________________"
"*****************************| NEXTCLOUD SHARES |******************************"
"**************************| Nextcloud File Manager |***************************"
"_____________________________________________________________________"
"                                                               "
"1. List all folders and files in $PWD                          "
"2. Search for files and folders in $PWD                        "
"3. Set Nextcloud URL                                           "
"4. Show Nextcloud URL                                          "
"5. Download content                                            "
"6. Upload content                                              "
"7. Exit                                                        " 
"__________________________________________________             "
" "
"SELECT AN OPTION BY USING UP AND DOWN ARROWS AND PRESSING ENTER"
)

selected_index=8 # Starts with option 1 highlighted
num_options=${#options[@]}

# Function to display the menu
display_menu() {
    clear
    for ((i=0; i<$num_options; i++)); do
        if [[ "${options[$i]}" =~ ^[0-9]+ ]]; then
            if [ $i -eq $selected_index ]; then
                echo -e "${green_high_intensity}|====> ${options[$i]}${reset}"
            else
                echo "   ${options[$i]}"
            fi
        elif [[ $i -eq 2 ]]; then
            echo "                   Today is: $(date '+%Y-%m-%d %H:%M:%S')   "
        else
            echo "   ${options[$i]}"
        fi
    done
}

# Function to handle user input for the main menu
handle_input_main_menu() {
    echo " "
    read -rsn1 input
    case $input in
        "A")  # Up arrow
            ((selected_index--))
            ;;
        "B")  # Down arrow
            ((selected_index++))
            ;;
        "")   # Enter key
            case $((selected_index - 8)) in
                0)
                    echo
                    echo "Accessed option 1... "
                    echo
                    list_folder_shares
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                1)
                    echo
                    echo "Accessed option 2... "
                    echo
                    search_files_and_folders
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                2)
                    echo
                    echo "Accessed option 3... "
                    echo
                    set_nextcloud_url
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                3)
                    echo
                    echo "Accessed option 4... "
                    echo
                    show_nextcloud_url
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                4)
                    echo
                    echo "Accessed option 5... "
                    download_content
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                5)
                    echo
                    echo "Accessed option 6... "
                    echo
                    upload_content
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                6)
                    echo
                    echo "Exiting program... "
                    echo
                    exit 0
                    ;;
                *)
                    echo
                    echo -e "${red_high_intensity}Invalid option. Please choose a valid option.${reset}"
                    echo
                    read -p "Press enter to get back to main menu: " enter
                    ;;
            esac
            ;;
    esac

    # Ensure selected_index stays within bounds
    if [ $selected_index -lt 8 ]; then
        selected_index=8
    elif [ $selected_index -ge 15 ]; then
        selected_index=14
    fi
}

# Main menu function
main_menu() {
    while true; do
        display_menu
        handle_input_main_menu
    done
}

# Start the script by showing the main menu
main_menu
