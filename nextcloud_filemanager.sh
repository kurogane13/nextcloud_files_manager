#!/bin/bash

# ANSI color codes
red="\033[31m"
red_high_intensity="\033[0;91m"
yellow="\033[33m"
yellow_high_intensity="\033[0;93m"
cyan="\033[4;36m"
cyan_high_intensity="\033[0;96m"
black="\033[0;30m"
cyan_high_background="\033[0;106m"
blue_high_background="\033[0;104m"
green_high_background="\033[0;102m"
green_highlight="\033[1;32m"
green_high_intensity="\033[0;92m"
normal="\033[0m"
reset="\033[0m"

# Default Nextcloud URL
nextcloud_url="nextcloud.com"

# Log directory and files
log_dir="nextcloud_logs"
download_log="$log_dir/nextcloud_downloads.log"
upload_log="$log_dir/nextcloud_uploads.log"

# Create the logs directory
mkdir -p "$log_dir"

# Function to set the Nextcloud URL
set_nextcloud_url() {
    echo
    read -p "Enter the Nextcloud URL: " nextcloud_url
    echo
    echo -e "Nextcloud URL set to: $nextcloud_url"
    echo
    read -p "Press enter to return to the main menu: " enter
    main_menu
}

# Function to show the current Nextcloud URL
show_nextcloud_url() {
    echo -e "Current Nextcloud URL: $nextcloud_url"
    echo
    read -p "Press enter to return to the main menu: " enter
    main_menu
}

# Function to list files and folders
list_folder_shares() {
    ls -lha
    echo "--------------------------------------------------------------"
    echo -e "Files and folders found with details:"
    echo
    results=$(find "$PWD" -type f -o -type d)
    while IFS= read -r item; do
        if [ -d "$item" ]; then
            echo -e "-------------------------------------------------------------------"
            echo -e "Directory: $item"
            du -sh "$item" | awk '{print $1 " " $2}'
        elif [ -f "$item" ]; then
            echo -e "-------------------------------------------------------------------"
            echo -e "File: $item"
            ls -lha "$item"
        fi
    done <<< "$results"
    echo -e "--------------------------------------------------------------"
    read -p "Press enter to get back to the main menu: " enter
    main_menu
}

# Function to search files and folders
search_files_and_folders() {
    echo
    read -p "Enter the regular expression to search for files and folders: " regexp
    echo
    echo -e "Searching for files and folders matching '$regexp' in $PWD..."
    results=$(find "$PWD" -type f -o -type d | grep -E "$regexp")
    
    if [ -z "$results" ]; then
        echo -e "${red_high_intensity}No files or folders found matching the regular expression '$regexp'${reset}."
    else
        echo -e "Files and folders found with details:"
        while IFS= read -r item; do
            if [ -d "$item" ]; then
                echo -e "-------------------------------------------------------------------"
                echo -e "Directory: $item"
                du -sh "$item" | awk '{print $1 " " $2}'
            elif [ -f "$item" ]; then
                echo -e "-------------------------------------------------------------------"
                echo -e "File: $item"
                ls -lha "$item"
            fi
        done <<< "$results"
    fi
    echo -e "--------------------------------------------------------------"
    read -p "Press enter to get back to the main menu: " enter
    main_menu
}

# Function to handle share links
share_link() {
    local share_link_file="share_link_file.txt"
    echo -e "Validating if the folder has a share link file..."
    if [[ -f "$folder_share/$share_link_file" ]]; then
        share_link=$(cat "$folder_share/$share_link_file")
        echo -e "Validation OK! This folder already has a share link file: $share_link_file"
    else
        echo -e "${red_high_intensity}No share link URL file was found for this folder.${reset}"
        read -p "Provide your share link URL, and press enter to proceed: " share_link
        echo -e "$share_link" > "$folder_share/$share_link_file"
    fi
}

# Function to download content
download_content() {
    unset zip_filename
    unset zip_file
    unset share_link
    unset share_link_file
    unset share_id
    unset download_url
    unset corrected_url

    echo
    ls -lha
    echo "---------------------------------------------------------------------"
    read -p "Enter the folder share, you to download content to (without '/' (e.g., nextcloud)): " folder_share

    if [[ ! -d $folder_share ]]; then
        echo
        echo -e "${red_high_intensity}$folder_share not found in $PWD.${reset}"
        echo
        read -p "Press enter to provide an existing folder and/or subfolder: " enter
        download_content
        return
    else
        echo
        echo "Showing Folder content: "
        echo
        ls -lha $folder_share
        echo
        echo "-----------------------------------------------------------------------------------"
        echo $folder_share" exists."
    fi

    local share_link_file_path="$folder_share/share_link_file.txt"
    if [[ -f "$share_link_file_path" ]]; then
        share_link=$(cat "$share_link_file_path")
        echo
        echo -e "Validation OK! This folder already has a share link file: $share_link_file_path"
        echo
    else
        echo
        echo -e "${red_high_intensity}share_link_file.txt not found in $folder_share.${reset}"
        echo
        read -p "Provide the share link URL, and press enter: " share_link
        echo "$share_link" > "$share_link_file_path"
    fi

	download_url=$(echo "$share_link" | sed -r 's#(/download)+$#/download#')
	datetimestamp=$(date +'%Y-%m-%d_%H-%M-%S')
	zip_filename="nextcloud_download_content_$datetimestamp.zip"
	zip_file="$folder_share/$zip_filename"

	# Construct the corrected URL for download
	corrected_url="${share_link}/download/${zip_filename}"
	
    echo "------------------------------------------------------------------------------------------"
    echo
    echo "You will download content from: $corrected_url"
    echo
    echo "Destination: local share folder: $folder_share/$zip_filename"
    echo
    echo "------------------------------------------------------------------------------------------"
    read -p "Press enter to proceed to download now: " enter
    echo
    echo "Downloading content from $corrected_url to $zip_file..."
    
    # Start the download
    start_time=$(date +'%Y-%m-%d %H:%M:%S')
    start_time_seconds=$(date -d "$start_time" +%s)
    curl -L -v "$corrected_url" -o "$zip_file"
    
    end_time=$(date +'%Y-%m-%d %H:%M:%S')
    end_time_seconds=$(date -d "$end_time" +%s)
    elapsed_time=$((end_time_seconds - start_time_seconds))
    
    # Convert elapsed time into hours, minutes, and seconds
    hours=$((elapsed_time / 3600))
    minutes=$(( (elapsed_time % 3600) / 60 ))
    seconds=$((elapsed_time % 60))
    
    # Format elapsed time
    formatted_elapsed_time=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
	
	echo "---------------------------------------------------------------------------------"
	echo
	echo " Curl operation timestamps for: curl -L -v $corrected_url -o $zip_file "
	echo
	echo "Start Time: $start_time"
	echo "End Time: $end_time"
	echo "Elapsed Time: $formatted_elapsed_time"
	echo

    if [[ $? -eq 0 ]]; then
        echo "--------------------------------------------------------------" >> "$download_log"
        echo -e "[$start_time] Downloaded content from $corrected_url to $zip_file" >> "$download_log"
        ls -lha "$zip_file" >> "$download_log"
        echo -e "Unzipping $zip_file..." >> "$download_log"
        unzip -o "$zip_file" -d "$folder_share"
        
        if [[ $? -eq 0 ]]; then
            rm -f "$zip_file"
            echo -e "[$end_time] Successfully unzipped $zip_file" >> "$download_log"
            echo -e "Listing all files in: $folder_share" >> "$download_log"
            ls -lha "$folder_share" >> "$download_log"
            echo "---------------------------------------------------------------------------" >> "$download_log"
			echo -e "[$start_time] - Downloading $zip_file to "$folder_share >> "$download_log"
			echo -e "[$end_time] - Ended download of $zip_file to "$folder_share >> "$download_log"
			echo -e "[$formatted_elapsed_time] - Elapsed time to download $zip_file to" $folder_share >> "$download_log"
            
        else
            echo -e "${red_high_intensity}Unzip failed. The file may be corrupted.${reset}"
            echo -e "[$end_time] Unzip failed for $zip_file" >> "$download_log"
        fi
    else
        echo -e "${red_high_intensity}Download failed. Please check the share link URL, or your connection.${reset}"
        echo -e "[$end_time] Download failed for $corrected_url" >> "$download_log"
    fi
    echo
    read -p "Press enter to get back to the main menu: " enter
    main_menu
}

# Function to upload content
upload_content() {
    echo "Do you want to upload a file or a folder?"
    echo
    echo "1) File"
    echo "2) Folder"
    echo "<--- b - Back to Main menu"
    echo
    read -p "Choose option 1, 2 or b to return to main menu: " choice
    
	unset temp_zip
	unset share_link
	unset share_link_file
	unset share_id
	unset upload_corrected_file_url
	
	unset folderpath
	unset foldername
	unset temp_zip
	unset share_link
	unset share_link_file
	unset share_id
	unset upload_corrected_folder_url

    case $choice in
        1)
            
            echo
            read -p "Enter the full path to the file (Example: My_folder/sub_folder/file.json): " filepath

            if [[ ! -f $filepath ]]; then
                echo
                echo -e "${red_high_intensity}ERROR: $filepath not found${reset}"
                echo
                read -p "Press enter to return to the main menu: " enter
                main_menu
            else
                echo
                ls -lha $filepath
                echo
                echo "---------------------------------------------------------------------"        
                # Define the file path for the share link file
                share_link_file="$(dirname "$filepath")/share_link_upload.txt"

                # Check if the share link file exists
                if [[ ! -f "$share_link_file" ]]; then
                    echo
                    echo -e "${red_high_intensity}Share link file not found. Please provide the share link.${reset}"
                    echo
                    read -p "Provide the share link URL to proceed with the upload of $filepath: " share_link
                    echo "$share_link" > "$share_link_file"
                else
                    share_link=$(<"$share_link_file")
                fi

                share_id="${share_link##*/}" # Remove everything before the last /

                filename=$(basename "$filepath")
                echo -e "Provided $filepath is valid"
                echo
                share_link_file="$(dirname "$filepath")/share_link_upload.txt"
                temp_zip="${filepath}.zip"
                echo
                echo "Compressing $filepath to $temp_zip..."
                echo
                zip -r "$temp_zip" "$filepath"

				# Construct the upload URL
				upload_corrected_file_url="https://${nextcloud_url}/public.php/webdav/${filename}"

				# Remove any extra slashes
				upload_corrected_file_url=$(echo "$upload_corrected_file_url" | sed 's|/public.php/webdav//|/public.php/webdav/|g')
				upload_corrected_file_url=$(echo "$upload_corrected_file_url" | sed 's|https://https://|https://|g')
				upload_corrected_file_url=$(echo "$upload_corrected_file_url" | sed 's|//public.php/|/public.php/|g')
                upload_url=$(echo "$share_link" | sed -r 's#(/download)+$#/upload#')

                echo
                echo "------------------------------------------------------------------------------------------------------"
                echo
                echo "Upload filename: $filepath"
                echo
                echo "Destination url: $upload_corrected_file_url."
                echo
                echo "------------------------------------------------------------------------------------------------------"
                read -p "Press enter to proceed to upload: " enter
                echo
                echo "Uploading $filepath to $upload_url..."
                echo
                start_time=$(date +'%Y-%m-%d %H:%M:%S')
                start_time_seconds=$(date -d "$start_time" +%s)
                echo
                echo "Upload started at: $start_time"
                echo

                # UPLOAD FILE CURL CALL
                curl_temp_log="curl_temp_log.log"
                touch $curl_temp_log
                curl -v -k -T "$temp_zip" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' "$upload_corrected_file_url" | tee -a "$curl_temp_log"
                
                # Check the log for a successful 201 response
                if grep -q "< HTTP/2 201" "$curl_temp_log"; then
                    echo
                    echo "Upload successful. Data was uploaded successfully."
                    echo "Upload successful. Data was uploaded successfully." >> "$upload_log"
                elif grep -q "error" "$curl_temp_log"; then
                    echo
                    echo "Upload failed. There were errors during the upload process." 
                    echo "Upload failed. There were errors during the upload process." >> "$upload_log"
                    echo "Check the log for more details:"
                    echo "Check the log for more details:" >> "$upload_log"
                    echo
                    tail -n 50 "$curl_temp_log"
                    tail -n 50 "$curl_temp_log" >> "$upload_log"
                    echo "------------------------------------------------------------------------"
                    echo "------------------------------------------------------------------------" >> "$upload_log"
                    echo
                    read -p "Press enter to return to the main menu: " enter
                    main_menu
                fi
                
                end_time=$(date +'%Y-%m-%d %H:%M:%S')
                end_time_seconds=$(date -d "$end_time" +%s)
                echo
                echo "Upload ended at: $end_time"
                echo
                elapsed_time=$((end_time_seconds - start_time_seconds))
                echo
                # Calculate elapsed time in seconds
                elapsed_seconds=$((end_time_seconds - start_time_seconds))
                
                # Convert elapsed time into hours, minutes, and seconds
                hours=$((elapsed_seconds / 3600))
                minutes=$(( (elapsed_seconds % 3600) / 60 ))
                seconds=$((elapsed_seconds % 60))
                
                # Format elapsed time
                formatted_elapsed_time=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
                
                echo
                echo "---------------------------------------------------------------------------------"
                echo
                echo "Curl operation timestamps for: curl -v -k -T $temp_zip -u $share_id: -H 'X-Requested-With: XMLHttpRequest' $upload_corrected_file_url"  >> "$upload_log"
                echo
                echo "Start Time: $start_time"
                echo "End Time: $end_time"
                echo "Elapsed Time: $formatted_elapsed_time"
                echo
                rm -rf $temp_zip
                rm -rf $filepath.zip
                rm -rf $curl_temp_log
                
                if [[ $? -eq 0 ]]; then
                    echo
                    echo -e "[$start_time] - Uploading $temp_zip to "$upload_corrected_file_url >> "$upload_log"
                    echo -e "[$end_time] - Ended upload of $temp_zip to "$upload_corrected_file_url >> "$upload_log"
                    echo -e "[$formatted_elapsed_time] - Elapsed time to upload $temp_zip to "$upload_corrected_file_url >> "$upload_log"
                    echo -e "${green_high_intensity}File uploaded successfully!${reset}" >> "$upload_log"
                else
                    echo
                    echo -e "${red_high_intensity}Upload failed. Please check the share link URL, or your connection.${reset}" >> "$upload_log"
                    echo
                    echo -e "[$end_time] Upload failed for "$upload_corrected_file_url >> "$upload_log"
                    echo
                fi
            fi
            ;;
        2)

            echo
            read -p "Enter the full path to the folder (without the '/'. e.g., /path/to/folder): " folderpath

            if [[ ! -d $folderpath ]]; then
                echo
                echo -e "${red_high_intensity}ERROR: $folderpath not found${reset}"
                echo
                read -p "Press enter to return to the main menu: " enter
                main_menu
            else
                foldername=$(basename "$folderpath")
                temp_zip="$folderpath.zip"
                
                echo
                ls -lha "$folderpath/"
                echo
                echo "---------------------------------------------------------------------"    
                echo
                echo -e "Compressing folder $folderpath to $temp_zip"
                echo
                zip -r "$temp_zip" "$folderpath"
                
                # Define the file path for the share link file
                share_link_file="$(dirname "$folderpath")/share_link_upload.txt"

                # Check if the share link file exists
                if [[ ! -f "$share_link_file" ]]; then
                    echo
                    echo -e "${red_high_intensity}Share link file not found. Please provide the share link.${reset}"
                    echo
                    read -p "Provide the share link URL to proceed with the upload of $folderpath: " share_link
                    echo "$share_link" > "$share_link_file"
                else
                    share_link=$(<"$share_link_file")
                fi
                
                share_id="${share_link##*/}" # Remove everything before the last /
                
				# Construct the upload URL
				upload_corrected_folder_url="https://${nextcloud_url}/public.php/webdav/${foldername}"

				# Remove any extra slashes
				upload_corrected_folder_url=$(echo "$upload_corrected_folder_url" | sed 's|/public.php/webdav//|/public.php/webdav/|g')
	            upload_corrected_folder_url=$(echo "$upload_corrected_folder_url" | sed 's|https://https://|https://|g')
				upload_corrected_folder_url=$(echo "$upload_corrected_folder_url" | sed 's|//public.php/|/public.php/|g')
                
                nextcloud_url=$(echo "$share_link" | sed -E 's|(https://[^/]+/).*|\1|') # Extract the base URL
                
                echo
                echo "You will be uploading all content from: $folderpath"
                echo
                echo "Destination URL: $upload_corrected_folder_url"
                echo
                echo "---------------------------------------------------------------------------------"
                read -p "Press enter to proceed to upload: " enter
                echo
                
                echo -e "Uploading $temp_zip to $upload_url..."
                
                start_time=$(date +'%Y-%m-%d %H:%M:%S')
                start_time_seconds=$(date -d "$start_time" +%s)
                echo
                echo "Upload started at: $start_time"
                echo
                
                curl_temp_log="curl_temp_log.log"
                touch $curl_temp_log
                # UPLOAD FOLDER CURL CALL
                curl -v -k -T $temp_zip -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' $upload_corrected_folder_url  | tee -a "$curl_temp_log"
                
                # Check the log for a successful 201 response
                if grep -q "< HTTP/2 201" "$curl_temp_log"; then
                    echo
                    echo "Upload successful. Data was uploaded successfully."
                    echo "Upload successful. Data was uploaded successfully." >> "$upload_log"
                elif grep -q "error" "$curl_temp_log"; then
                    echo
                    echo "Upload failed. There were errors during the upload process." 
                    echo "Upload failed. There were errors during the upload process." >> "$upload_log"
                    echo "Check the log for more details:"
                    echo "Check the log for more details:" >> "$upload_log"
                    echo
                    tail -n 50 "$curl_temp_log"
                    tail -n 50 "$curl_temp_log" >> "$upload_log"
                    echo "------------------------------------------------------------------------"
                    echo "------------------------------------------------------------------------" >> "$upload_log"
                    echo
                    read -p "Press enter to return to the main menu: " enter
                    main_menu
                fi
                
                end_time=$(date +'%Y-%m-%d %H:%M:%S')
                end_time_seconds=$(date -d "$end_time" +%s)
                echo
                echo "Upload ended at: $end_time"
                echo
                elapsed_time=$((end_time_seconds - start_time_seconds))
                echo
                # Calculate elapsed time in seconds
                elapsed_seconds=$((end_time_seconds - start_time_seconds))
                
                # Convert elapsed time into hours, minutes, and seconds
                hours=$((elapsed_seconds / 3600))
                minutes=$(( (elapsed_seconds % 3600) / 60 ))
                seconds=$((elapsed_seconds % 60))
                
                # Format elapsed time
                formatted_elapsed_time=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)
                
                echo
                echo "---------------------------------------------------------------------------------"
                echo
                echo "Curl operation timestamps for: curl -v -k -T $temp_zip -u $share_id: -H 'X-Requested-With: XMLHttpRequest' $upload_corrected_folder_url"  >> "$upload_log"
                echo
                echo "Start Time: $start_time"
                echo "End Time: $end_time"
                echo "Elapsed Time: $formatted_elapsed_time"
                echo
                rm -rf $temp_zip
                rm -rf $filepath.zip
                rm -rf $curl_temp_log
                
                if [[ $? -eq 0 ]]; then
                    echo
                    echo -e "[$start_time] - Uploading $temp_zip to "$upload_corrected_folder_url >> "$upload_log"
                    echo -e "[$end_time] - Ended upload of $temp_zip to "$upload_corrected_folder_url >> "$upload_log"
                    echo -e "[$formatted_elapsed_time] - Elapsed time to upload $temp_zip to "$upload_corrected_folder_url >> "$upload_log"
                    echo -e "${green_high_intensity}File uploaded successfully!${reset}" >> "$upload_log"
                else
                    echo
                    echo -e "${red_high_intensity}Upload failed. Please check the share link URL, or your connection.${reset}" >> "$upload_log"
                    echo
                    echo -e "[$end_time] Upload failed for "$upload_corrected_folder_url >> "$upload_log"
                    echo
                fi
            fi
            ;;
        b)
            main_menu
            ;;
        *)
            echo
            echo "Invalid option. Please choose 1, 2 or b."
            upload_content
            ;;
    esac
}


# Function to view download log
view_download_log() {
	echo
    echo -e "Reading the download log file: $download_log"
    if [[ -f $download_log ]]; then
        echo
        echo "BELOW THIS LINE STARTS THE OUTPUT OF: $download_log"
        echo "------------------------------------------------------------------------------"
        cat "$download_log"
        echo "------------------------------------------------------------------------------"
        echo "ABOVE THIS LINE ENDS THE OUTPUT OF: $download_log"
    else
        echo
        echo -e "${red_high_intensity}Log file $download_log does not exist.${reset}"
    fi
    echo
    read -p "Press enter to return to the main menu: " enter
    main_menu
}

# Function to view upload log
view_upload_log() {
	echo
    echo -e "Reading the upload log file: $upload_log"
    if [[ -f $upload_log ]]; then
        echo
        echo "BELOW THIS LINE STARTS THE OUTPUT OF: $upload_log"
        echo "------------------------------------------------------------------------------"
        cat "$upload_log"
        echo "------------------------------------------------------------------------------"
        echo "ABOVE THIS LINE ENDS THE OUTPUT OF: $upload_log"
    else
        echo
        echo -e "${red_high_intensity}Log file $upload_log does not exist.${reset}"
    fi
    echo
    read -p "Press enter to return to the main menu: " enter
    main_menu
}

# Function to search in log files
search_in_log_files() {
    # Define log directory and log files
    log_dir="nextcloud_logs"
    download_log="$log_dir/nextcloud_downloads.log"
    upload_log="$log_dir/nextcloud_uploads.log"

    # Validate if the log directory exists
    if [ ! -d "$log_dir" ]; then
        echo
        echo -e "${red_high_intensity}The log directory '$log_dir' does not exist.${reset}"
        echo
        read -p "Press enter to get back to the main menu: " enter
        main_menu
        return
    fi

    # Check if log files exist
    if [ ! -f "$download_log" ] && [ ! -f "$upload_log" ]; then
        echo
        echo -e "${red_high_intensity}Neither the download log file '$download_log' nor the upload log file '$upload_log' exists.${reset}"
        echo
        read -p "Press enter to get back to the main menu: " enter
        main_menu
        return
    fi

    echo "-------------------------------------------------------------------------"
    echo
    echo -e "Select the log file to search in:"
    echo
    echo -e "1. Download log ($download_log)"
    echo -e "2. Upload log ($upload_log)"
    echo -e "3. Back to main menu"
    echo

    # Read user choice
    read -p "Enter your choice (1, 2, or 3): " choice

    case "$choice" in
        1)
            selected_log="$download_log"
            ;;
        2)
            selected_log="$upload_log"
            ;;
        3)
            main_menu
            return
            ;;
        *)
            echo
            echo -e "${red_high_intensity}Invalid choice. Returning to main menu.${reset}"
            echo
            read -p "Press enter to return to search mode: " enter
            search_in_log_files
            return
            ;;
    esac

    # Ensure the selected log file exists
    if [ ! -f "$selected_log" ]; then
        echo
        echo -e "${red_high_intensity}The selected log file '$selected_log' does not exist.${reset}"
        echo
        read -p "Press enter to get back to the main menu: " enter
        main_menu
        return
    fi

    # Proceed with the search
    echo
    read -p "Enter the regular expression to search for in the log file: " regexp
    echo
    echo -e "Searching for entries matching '$regexp' in '$selected_log'..."
    echo
    results=$(grep -E "$regexp" "$selected_log")

    if [ -z "$results" ]; then
        echo
        echo -e "${red_high_intensity}No entries found matching the regular expression '$regexp'.${reset}"
        echo
    else
        echo
        echo -e "Entries found in '$selected_log':"
        echo -e "--------------------------------------------------------------"
        echo "$results"
        echo -e "--------------------------------------------------------------"
    fi

    read -p "Press enter to get back to the main menu: " enter
    main_menu
}

# Array of options
options=(
"####################### *** FILE SHARES MANAGER *** ###########################"
"                                                                               "
"                    Today is:                                                  "
"_______________________________________________________________________________"
"*****************************| NEXTCLOUD SHARES |******************************"
"************************* | Nextcloud File Manager |***************************"
"_______________________________________________________________________________"
"                                                               "
"1. List all folders and files in $PWD                          "
"2. Search for files and folders in $PWD                        "
"3. Set Nextcloud URL                                           "
"4. Show Nextcloud URL                                          "
"5. Download content                                            "
"6. Upload content                                              "
"7. View Downloads log                                          "
"8. View Uploads log                                            "
"9. Search regular expressions in log files                     "
"10. Exit                                                       " 
"_______________________________________________________________________________"
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
                    echo "Accessed option 7... "
                    echo
                    view_download_log
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                7)
                    echo
                    echo "Accessed option 8... "
                    echo
                    view_upload_log
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                8)
                    echo
                    echo "Accessed option 9... "
                    echo
                    search_in_log_files
                    read -p "Press enter to get back to main menu: " enter
                    ;;
                9)
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
    elif [ $selected_index -ge 18 ]; then
        selected_index=8
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
