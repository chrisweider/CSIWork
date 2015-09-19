#command line parameters
param([string]$SourceDir, [string]$ExcludeFiles)

# source dir can't be empty
if ([string]::IsNullOrEmpty($SourceDir))
{
    Write-Host "Source dir not specified" -ForegroundColor Red
    Exit
}

#source dir has to exist
if (-Not (Test-Path $SourceDir))
{
    Write-Host "Folder $SourceDir doesn't exist" -ForegroundColor Red
    Exit
}

# collect all files in source dir recursively
$TotalFiles = Get-ChildItem -Path $SourceDir -Recurse -Exclude $ExcludeFiles

# count files total
$TotalFilesCount = $TotalFiles.Count
Write-Host "Total files: $TotalFilesCount"

# if no files found stop
if ($TotalFilesCount -eq 0)
{
    Write-Host "No files found in $SourceDir" -ForegroundColor Red
    Exit
}

# count files not older then 90 days from current date
$RefreshedFilesCount = 
    ($TotalFiles | 
        Where-Object { (New-TimeSpan -Start $_.LastWriteTime -End (Get-Date)).TotalDays -lt 90 }).Count
 Write-Host "Refreshed files: $RefreshedFilesCount"

 # count percentage
 $Refreshness = $RefreshedFilesCount / $TotalFilesCount * 100
 Write-Host "Refreshness: $Refreshness%"