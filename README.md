# LC_backup_save_file
Enables lethal company save files to be restored in the case you get griefed

# Requirements:
Windows machine

# How to install:
1. [download the powershell script](LC_backup_setup.ps1)
2. move the powershell script to desktop (or somewhere you can access easily while playing the game)
3. run the powershell script
    - You will probably need to right click `run with powershell`

It will generate 2 or 4 files in the directory that you run the powershell script:
- RunBackup_fs.bat
    - Creates a backup (using file systems copy paste)
- RunRestore_fs.bat
    - Restores from the backups (using file systems copy paste)
If you have `git` installed:  
- QuickBackup.bat
    - Commits to a local git repo 
- QuickRestore.bat
    - Restores local files to git's HEAD (removes noncomitted/unsaved changes)
    - yes you can use git reset <hash> to restore from a specific git version.
 


# stuff i might do later:
add a way to auto-watch for file changes and commit to git tree.
improve accessability for restoring from git tree by adding UI to navigate between commits.






# How to use
1. install
2. play LC like normal
3. run `QuickBackup.bat` or `RunBackup_fs.bat` at any point before the game file saves (end of day, or whatever it is)
4. if you get griefed, whenever you want to return to a pre-griefed state, run `QuickRestore.bat` or `RunRestore_fs.bat` and reload your save file ingame.
