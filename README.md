# AUTHOR: Gustavo Wydler Azuaga
# Date: 07/22/2024

# Nextcloud Shares File Manager

## Overview
A simple bash script to manage Nextcloud shares directly from the command line. Easily download and upload files or folders using public share links.

## Features
- **List Folders and Files**: Display all files and folders in the current directory.
- **Download Content**: Retrieve files and folders from a Nextcloud share.
- **Upload Content**: Upload files or folders to a Nextcloud share.

## Public Share Links
- **What They Are**: URLs provided by Nextcloud for accessing shared content.
- **How It Works**: The script uses these links to perform download and upload operations via WebDAV.

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

## Usage
1. **List Folders and Files**: Select option `1` from the main menu.
2. **Download Content**: Select option `2` and provide the necessary folder and share link.
3. **Upload Content**: Select option `3` and choose to upload either a file or a folder, then provide the path and share link.

---

Enjoy managing your Nextcloud shares effortlessly!
