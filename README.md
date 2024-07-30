# AUTHOR: Gustavo Wydler Azuaga
# Date: 07/22/2024

# Nextcloud Shares File Manager

## Overview
A simple bash script to manage Nextcloud shares directly from the command line. Easily download and upload files or folders using public share links.

## Public Share Links
- **What They Are**: URLs provided by Nextcloud for accessing shared content.
- **How It Works**: The script uses these links to perform download and upload operations via WebDAV.

## Features option list

1. **List all folders and files in the current directory**
   - Lists all the folders and files in the current working directory (`$PWD`) with detailed information.

2. **Search for files and folders in the current directory**
   - Searches for files and folders in the current working directory (`$PWD`) matching a regular expression provided by the user.

3. **Set Nextcloud URL**
   - Allows you to set the Nextcloud URL to be used for file management operations.

4. **Show Nextcloud URL**
   - Displays the currently set Nextcloud URL.

5. **Download content**
   - Downloads content from a specified Nextcloud share link to a specified local path.

6. **Upload content**
   - Uploads files or folders to a specified Nextcloud share link. Compresses folders into a zip file before uploading, and decompresses them on the server.

7. **View Downloads Log**
   - View the log of download operations.
8. **View Uploads Log**
   - View the log of upload operations.
9. **Search Regular Expressions in Log Files**
   - Searches for specific patterns in the log files.

10. **Exit**
   - Exits the script.

## Usage

### List all folders and files

Lists all the folders and files in the current working directory with detailed information including sizes and permissions.

### Search for files and folders

Allows you to search for files and folders in the current working directory that match a regular expression provided by the user. It displays detailed information about each matching file and folder.

### Set Nextcloud URL

Set the Nextcloud URL that will be used for uploading and downloading files. You only need to set this once unless the URL changes.

### Show Nextcloud URL

Displays the currently set Nextcloud URL.

### Download content

Download content from a Nextcloud share link to a specified local path. You need to provide the share link and the local path where you want to save the downloaded content.

### Upload content

Upload files or folders to a Nextcloud share link. You can choose to upload either a file or a folder. If uploading a folder, it will be compressed into a zip file before uploading, and decompressed on the server after uploading.

### View Downloads Log

View the log of curl downloaded operations with datetime timestamps.

### View Uploads Log

View the log of curl upload operations with datetime timestamps.

### Search Regular Expressions in Log Files

Search for regular expressions strings in download or upload logs.

## How to Run
1. **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/nextcloud-shares-file-manager.git
    cd nextcloud-shares-file-manager
    ```
2. **Make the script executable**:
    ```bash
    chmod +x nextcloud_filemanager.sh
    ```
3. **Run the script**:
    ```bash
    ./nextcloud_filemanager.sh
    ```

## Dependencies

- `curl`
- `wget`
- `zip`
- `du`
- `awk`

Make sure these dependencies are installed on your system before running the script.

---

Enjoy managing your Nextcloud shares effortlessly!
