#!/bin/bash

list_folder_shares() {
    ls -lha
    echo "--------------------------------------------------------------"
    read -p "Press enter to get back to the main menu: " enter
    main_menu
}

share_link() {

    # Define the file path
    share_link_file="share_link_file.txt"
    echo
    echo "Validating if the folder has a share link file..."
	echo
    # Check if the share link file already exists
    if [[ -f "$folder_share/$share_link_file" ]]; then
        share_link=$(cat "$share_link_file")
        echo
        echo "Validation OK!. This folder already has a share link file: $share_link_file"
        echo
    else
        # Prompt for the share link URL
        echo
        read -p "No share link URL file was found for this folder: Provide your share link url, and press enter to proceed: " share_link

        # Create the file and write the share link to it
        echo "$share_link" > "$folder_share/$share_link_file"
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
		  echo "$folder_share not found in $PWD."
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
    
    # Get the share link URL
    share_link
    
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
    echo "Downloading content from $corrected_url to $zip_file..."
    echo
    
    # Perform the download using curl
    curl -L -v "$corrected_url" -o "$zip_file"
    
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
            echo "Unzip failed. The file may be corrupted."
        fi
    else
        echo "Download failed. Please check the share link or your connection."
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
    echo
    read -p "Choose an option (1 or 2): " choice

    if [[ $choice -eq 1 ]]; then
        # Ask for the full path to the file
        echo
        read -p "Enter the full path to the file (Example: My_folder/sub_folder/file.json): " filepath
        filename=$(basename "$filepath")
        
        if [[ ! -f $filepath ]];then
            echo
            echo "ERROR: $filepath not found"
            echo
            read -p "Press enter to return to the main menu: "
            echo
            upload_content
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
            echo "Share link file not found. Please provide the share link."
            echo
            read -p "Provide the share link URL, to proceed with the oupload of $filepath: " share_link
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
            curl -v -k -T "$temp_zip" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' $corrected_url2

            if [[ $? -eq 0 ]]; then
                echo
                echo "File $filename uploaded successfully."
            else
                echo
                echo "Failed to upload file $filename."
            fi

            # Clean up the temporary zip file
            rm -f "$temp_zip"
        else
            echo
            echo "File $filepath does not exist."
            echo
            read -p "Press enter to return to the menu: " enter
            upload_content
        fi
    elif [[ $choice -eq 2 ]]; then
        # Ask for the full path to the folder
        echo
        read -p "Enter the full path to the folder you want to upload to Nextcloud without the last '/' (Example: /root/My_folder): " folder_share
        foldername=$(basename "$folder_share")
        temp_zip="$folder_share.zip"
        
        if [[ ! -d $folder_share ]];then
            echo
            echo "ERROR: Folder share: $folder_share not found"
            echo
            read -p "Press enter to return to the main menu: "
            echo
            upload_content
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
            echo "Share link file not found. Please provide the share link."
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
            curl -v -k -T "$temp_zip" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' $corrected_url2

            if [[ $? -eq 0 ]]; then
                echo
                echo "Folder $foldername uploaded successfully."
            else
                echo
                echo "Failed to upload folder $foldername."
            fi

            # Clean up the temporary zip file
            rm -f "$temp_zip"
        else
            echo
            echo "Folder $folder_share does not exist."
            echo
            read -p "Press enter to return to the menu: " enter
            upload_content
        fi
    else
        echo
        echo "Invalid choice. Please select 1 for file or 2 for folder."
    fi
    echo
    read -p "Press Enter to return to the main menu..."
}


main_menu() {
    while true; do
        clear
        echo "=============================="
        echo " Nextcloud Shares File Manager "debug2: channel 0: window 999236 sent adjust 49340

        echo "=============================="
        echo "1. List all folders and files in $PWD"
        echo "2. Download all content from a Nextcloud share"
        echo "3. Upload all content to a Nextcloud share"
        echo "4. Exit"
        echo "=============================="
        echo -n "Select an option [1-4]: "
        read -r option

        case $option in
            1) list_folder_shares ;;
            2) download_content ;;
            3) upload_content ;;
            4) exit ;;
            *) echo "Invalid option. Please select a number between 1 and 4." ;;
        esac
    done
}

main_menu

