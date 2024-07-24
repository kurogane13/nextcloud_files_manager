#!/bin/bash

list_folder_shares() {
    ls -lha
    echo "--------------------------------------------------------------"
    read -p "Press enter to get back to the main menu: " enter
    main_menu
}

download_content() {
    echo 
    ls -lha
    echo
    echo "---------------------------------------------------------------------"
    
    # Prompt user for input
    read -p "Enter the folder share to download content to (e.g., nextcloud): " folder_share
    echo
    echo "You will be downloading content from nextcloud to folder: $folder_share"
    echo
    echo "All the content will be downloaded in a zip file called nextcloud_download_content.zip with a datetime timestamp."
    echo
    read -p "Press enter to proceed: " enter

    # Define the file path
    share_link_file="$folder_share/share_link_download.txt"

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$share_link_file")"

    # Check if the share link file already exists
    if [[ -f "$share_link_file" ]]; then
        share_link=$(cat "$share_link_file")
        echo "This folder already has a download link: $share_link"
        echo
    else
        # Prompt for the share link URL
        read -p "Provide your share link url, to download all content to your $folder_share folder: " share_link

        # Create the file and write the share link to it
        echo "$share_link" > "$share_link_file"
    fi

    # Clean the share link URL and append /download if necessary
    download_url=$(echo "$share_link" | sed -r 's#(/download)+$#/download#')
    download_url="${download_url}/download"

    # Get the current datetime and format it for the filename
    datetimestamp=$(date +'%Y-%m-%d_%H-%M-%S')
    zip_filename="nextcloud_download_content_$datetimestamp.zip"
    zip_file="$folder_share/$zip_filename"
    echo
    echo "Downloading content from $download_url to $zip_file..."
    echo
    
    # Perform the download using curl
    curl -L -v "$download_url" -o "$zip_file"

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        echo "--------------------------------------------------------------"
        ls -lha "$zip_file"
        echo
        echo "Unzipping $zip_file..."
        echo
        
        # Unzip the file
        unzip "$zip_file" -d "$folder_share"
        echo
        echo "Listing all files in: $folder_share"
        ls -lha "$folder_share"
        echo "--------------------------------------------------------------"
    else
        echo "Download failed. Please check the share link or your connection."
    fi

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

    # Define the file path for the share link file
    share_link_file="$folder_share/share_link_upload.txt"

    if [[ $choice -eq 1 ]] || [[ $choice -eq 2 ]]; then
        # Check if the share link file exists
        if [[ -f "$share_link_file" ]]; then
            share_link=$(cat "$share_link_file")
            echo
            echo "This folder already has an upload link: $share_link"
        else
            echo
            echo "No share link found in $folder_share"
            # Prompt for the share link URL
            echo
            read -p "Provide your share link URL, to upload all content to your $folder_share folder: " share_link
            # Create the file and write the share link to it
            echo "$share_link" > "$share_link_file"
        fi

        # Get the share ID from the share link
        share_id=$(echo "$share_link" | sed -n 's#https://nc.cloudlinux.com/s/\([^/]*\)$#\1#p')

        if [[ $choice -eq 1 ]]; then
            # Ask for the full path to the file
            echo
            read -p "Enter the full path to the file: " filepath
            filename=$(basename "$filepath")
            filedir=$(dirname "$filepath")

            # Check if the file exists
            if [[ -f "$filepath" ]]; then
                # Construct the URL for the file
                corrected_url="https://nc.cloudlinux.com/public.php/webdav/$folder_share/$filename"
                corrected_url=$(echo "$corrected_url" | sed 's|/webdav//|/webdav/|g')

                # Perform the upload using curl
                echo
                echo "Uploading $filename to $corrected_url..."
                curl -v -k -T "$filepath" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' "$corrected_url"

                if [[ $? -eq 0 ]]; then
                    echo
                    echo "File $filename uploaded successfully."
                else
                    echo
                    echo "Failed to upload file $filename."
                fi
            else
                echo
                echo "File $filepath does not exist."
            fi
        elif [[ $choice -eq 2 ]]; then
            # Ask for the full path to the folder
            echo
            read -p "Enter the full path to the folder you want to upload to Nextcloud (Example: /root/My_folder): " folderpath
            foldername=$(basename "$folderpath")
            temp_zip="$folderpath.zip"

            # Check if the folder exists
            if [[ -d "$folderpath" ]]; then
                # Compress the folder using zip
                echo
                echo "Compressing $folderpath to $temp_zip..."
                zip -r "$temp_zip" "$folderpath"

                # Construct the URL for the folder
                corrected_url="https://nc.cloudlinux.com/public.php/webdav/$folder_share/$temp_zip"
                corrected_url=$(echo "$corrected_url" | sed 's|/webdav//|/webdav/|g')

                # Perform the upload using curl
                echo
                echo "Uploading $temp_zip to $corrected_url..."
                curl -v -k -T "$temp_zip" -u "$share_id:" -H 'X-Requested-With: XMLHttpRequest' "$corrected_url"

                if [[ $? -eq 0 ]]; then
                    echo
                    echo "Folder $foldername uploaded successfully."
                else
                    echo
                    echo "Failed to upload folder $foldername."
                fi

                # Clean up the temporary zip file
                rm "$temp_zip"
            else
                echo
                echo "Folder $folderpath does not exist."
            fi
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
        echo " Nextcloud Shares File Manager "
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
