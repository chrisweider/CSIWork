#command line parameters
param(
    [Parameter(Mandatory=$True)] [string]$SourceDir,
	[Parameter(Mandatory=$True)] [string]$OutFile,
    [string]$Filter
)

# source dir can't be empty
if ([string]::IsNullOrEmpty($SourceDir))
{
    Write-Warning "Source dir not specified"
    Exit
}

#source dir has to exist
if (-Not (Test-Path $SourceDir))
{
    Write-Warning "Folder $SourceDir doesn't exist"
    Exit
}

# create out file if it doesn't exist
if (Test-Path $OutFile)
{
	Write-Warning "File $OutFile already exists"
	Exit
}

# collect all files in source dir recursively
$TotalFiles = Get-ChildItem -Path $SourceDir -Recurse -Filter $Filter

# count files total
$TotalFilesCount = $TotalFiles.Count
Write-Output "Total files: $TotalFilesCount"

# if no files found stop
if ($TotalFilesCount -eq 0)
{
    Write-Output "No files found in $SourceDir" -ForegroundColor Red
    Exit
}

# organize all content from source dir into a table and outfile
"File Name,File State" | Out-File $OutFile
foreach ($File in $TotalFiles)
{
	$TimeGap = (New-TimeSpan -Start $File.LastWriteTime -End (Get-Date)).TotalDays
	
	$FileState = "unknown"
	if ($TimeGap -gt 90)
    {
        $FileState = "abandoned"
    }
    elseif (($TimeGap -gt 70) -and ($TimeGap -le 90))
    {
        $FileState = "almost stale"
    }
    else
    {
        $FileState = "fresh"
    }

	"$File,$FileState" | Out-File $OutFile -Append
}

# count files not older then 90 days from current date
$RefreshedFilesCount = 
    ($TotalFiles | 
        Where-Object { (New-TimeSpan -Start $_.LastWriteTime -End (Get-Date)).TotalDays -lt 90 }).Count
 Write-Output "Refreshed files: $RefreshedFilesCount"

 # count percentage
 $Refreshness = $RefreshedFilesCount / $TotalFilesCount * 100
 Write-Output "Refreshness: $Refreshness%"