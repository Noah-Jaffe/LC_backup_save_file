# CONFIG
$BACKUP_FILES = @("LCChallengeFile","LCGeneralSaveData","LCSaveFile1","LCSaveFile2","LCSaveFile3","SaveFile.es3")

# VARS
$CWD = (Get-Location).path
$LC_LOCAL_PATH = $env:LOCALAPPDATA + "Low\ZeekerssRBLX\Lethal Company"
$USE_GIT = $false
# note: cant use simple gitignore bc powershell does not write utf-8 that can be properly be picked up by git
$gitExcludes = @("*.txt", "*.log","*.ps1","*.bat","!LCChallangeFile","!LCGeneralSaveData", "!LCSaveFile*", "!SaveFile.es3")
$gitignoreFileName = ".gitignore"
$gitignoreContents = @"
*.txt`r`n
*.log`r`n
*.ps1`r`n
*.bat`r`n
`r`n
# never ignore these files`r`n
!LCChallangeFile`r`n
!LCGeneralSaveData`r`n
!LCSaveFile`r`n
!SaveFile.es3`r`n
"@

$inefficientBackupDirectory = "$($env:LOCALAPPDATA)Low\ZeekerssRBLX\Lethal Company\Backups"
$inefficientBackupFilePath = "$($env:LOCALAPPDATA)Low\ZeekerssRBLX\Lethal Company\BackupLCSaveFiles_fs.ps1"
$inefficientBackupExecutableName = "RunBackup_fs.bat"
$inefficientBackupContents = @"
# V0.1 --> Only save latest version
Set-Location `$PSScriptRoot
`$filesToSave = @("$($BACKUP_FILES -join '","')")
`$saveDirectory = "$($inefficientBackupDirectory)"
if (!(Test-Path -Path `$saveDirectory)) {
    mkdir `$saveDirectory
}
Get-ChildItem |
Foreach-Object {
    if (`$filesToSave.Contains(`$_.Name)) {
        Write-Host Saving `$_.FullName
        Copy-Item `$_.FullName -Destination `$saveDirectory
    }
}
"@

$inefficientRestoreFilePath = "$($env:LOCALAPPDATA)Low\ZeekerssRBLX\Lethal Company\RestoreLCSaveFiles_fs.ps1"
$inefficientRestoreExecutableName = "RunRestore_fs.bat"
$inefficientRestoreContents = @"
# V0.1 --> Only restore from single version
Set-Location `$PSScriptRoot
`$saveDirectory = "$($inefficientBackupDirectory)"
if (!(Test-Path -Path `$saveDirectory)) {
    Write-Host "Backup directory not found!"
    Exit 1
}
Copy-Item -Path `$saveDirectory\* -Destination `$PSScriptRoot -Recurse
Write-Host Restored!
"@

$askToInstallGitMsg = @"
You do not have git installed.
[Yes] => Will install it now.
[No] => Will use a less efficent method of creating backups.

Protip: Don't install things you are not familiar with. That includes git if you haven't heard of it. Although, if you got this far, why not do it anyways 🤡
"@

$quickBackupFilePath = "$($env:LOCALAPPDATA)Low\ZeekerssRBLX\Lethal Company\BackupLCSaveFiles_git.ps1"
$quickBackupExecutableName = "QuickBackup.bat"
$quickBackupWithGitContents = @"
Set-Location `$PSScriptRoot
try
{
    # attempt to commit current file contents to repo
    git add -A
    git commit --allow-empty-message --no-edit
    git log -n 1 --pretty=format:"Last saved hash: %H%nLast saved timestamp: %aD"
    pause
}
catch
{
    Write-Host "Failed to backup data to git repo, will use the inefficient method instead!"
    $($CWD)/$($inefficientBackupFilePath)
}
"@
$quickRestoreFilePath = $env:LOCALAPPDATA + "Low\ZeekerssRBLX\Lethal Company\RestoreLCSaveFiles_git.ps1"
$quickRestoreExecutableName = "QuickRestore.bat"
$quickRestoreGitContents = @"
Set-Location `$PSScriptRoot
`$msgBoxInput =  [System.Windows.Forms.MessageBox]::Show("This will reset latest unsaved progress, are you sure you want to continue?",'Restore?','YesNoCancel','Error')
if (`$msgBoxInput -eq 'Yes') {
    git reset --hard
    git log -n 1 --pretty=format:"Restored from hash: %H%nRestored from timestamp: %aD"
}
"@

Function WriteBatFileToExecPs1($outfilePath, $ps1FilePath){
Write-Host $outfilePath
Write-Host $ps1FilePath
    $content = @"
powershell.exe -ExecutionPolicy Bypass -File "$($ps1FilePath)"
pause
"@
    Set-Content -Path "$($CWD)\$($outfilePath)" -Value $content
}
# RUN

## Test for expected directory
if (!(Test-Path -Path $LC_LOCAL_PATH)) { 
    Write-Host "I CANT FIND YOUR LETHAL COMPANY DIRECTORY CONTAINING YOUR SAVE FILES!"
    Write-Host "I dont feel like writing complex code to figure it out so ill just say gg, glhf for now, ask around"
    Pause
    Exit 1
}

## Is git is installed?
try
{
    git | Out-Null
    $USE_GIT = $true
}
catch [System.Management.Automation.CommandNotFoundException]
{

    $msgBoxInput = [System.Windows.Forms.MessageBox]::Show($askToInstallGitMsg,'Install Git?','YesNoCancel','Error')
    switch  ($msgBoxInput) {
    'Yes' {
        [System.Windows.Forms.MessageBox]::Show('We are about to install git, after git is installed you might need to re-run this script!')
        winget install --id Git.Git -e --source winget
    }
    'No' {
        Write-Host "We will not install git, script will generate script to generate backups purely with copy/paste files."
    }
    'Cancel' {
        Write-Host "Canceled"
        Exit 3
    }
  }
}

## Write the simlpe way to save files, (to be used as a backup if git fails somehow)
Set-Content -Path $inefficientBackupFilePath -Value $inefficientBackupContents
# writes quick executable to wherever you are running this from.
WriteBatFileToExecPs1 $inefficientBackupExecutableName $inefficientBackupFilePath
Write-Host "The less efficent method of backing up your save files can be executed by simply executing the file: $($inefficientBackupExecutableName)"
Set-Content -Path $inefficientRestoreFilePath -Value $inefficientRestoreContents
WriteBatFileToExecPs1 $inefficientRestoreExecutableName $inefficientRestoreFilePath

if ($USE_GIT) {
    Write-Host "We will also write the better method of creating backups via the git command."

    ## STEP 1: Go to the directory where the LC save files exist
    Set-Location $LC_LOCAL_PATH | Out-Null

    ## STEP 2: Initalize a git repo
    if (!(Test-Path "$($LC_LOCAL_PATH)\.git")) {
        Write-Host "Creating git repo at this location $(pwd)"
        git init | Out-Null
    } else {
        Write-Host "Git repo already exists at this location $(pwd)"
    }

    ## STEP 3: Generate the .gitignore file
    ### note: cant use simple gitignore bc powershell does not write utf-8 that can be properly be picked up by git will write directly to .git/info/exclude
    Write-Host "Writing gitignore file so we dont save useless log files"
    Set-Content -Path $gitignoreFileName -Value $gitignoreContents -Encoding UTF8

    ## STEP 4: Commit .gitignore file to repo
    Write-Host "Committing .gitignore file to repo"
    git add $gitignoreFileName | Out-Null
    git commit -m "Adding .gitignore" | Out-Null
    ## note: not git push, if you want to be able to transfer save files then maybe add an upstream origin.

    ## STEP 5: write QuickBackup, and QuickRestore script and executable
    Set-Content -Path $quickBackupFilePath -Value $quickBackupWithGitContents
    WriteBatFileToExecPs1 $quickBackupExecutableName $quickBackupFilePath
    Write-Host "Backing up your save files can be executed by simply executing the file: $($quickBackupExecutableName)"
    Set-Content -Path $quickRestoreFilePath -Value $quickRestoreGitContents
    WriteBatFileToExecPs1 $quickRestoreExecutableName $quickRestoreFilePath
   
}

$saveOptExe = $inefficientBackupExecutableName
$restoreOptExe = $inefficientRestoreExecutableName
if ($USE_GIT) {
    $saveOptExe = "$($quickBackupExecutableName) OR $($saveOptExe)"
    $restoreOptExe = "$($quickRestoreExecutableName) OR $($restoreOptExe)"
}

$report = @"
Completed setup, read the command line logs!
Pressing OK will close this window and the script logs!




TL;DR: 
Backup save files by running: $($saveOptExe)
Restore save files by running: $($restoreOptExe)
Should work even while game is running.
"@

[System.Windows.Forms.MessageBox]::Show($report)
