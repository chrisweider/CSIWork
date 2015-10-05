#command line parameters
param(
    [Parameter(Mandatory=$True)] [string]$SourceDir,
    [Parameter(Mandatory=$True)] [string]$OutFile,
    [string]$Filter
)

function checkCmdLineParams()
{
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
}

function main()
{
    checkCmdLineParams

    # collect all files in source dir recursively
    $TotalFiles = GetFilesFromRepo($SourceDir)

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
        $TimeGap = (New-TimeSpan -Start $($File.CommitDate) -End (Get-Date)).TotalDays
    
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

        "$($File.Name),$FileState" | Out-File $OutFile -Append
    }

    Write-Output "Generated file $OutFile"

    # count files not older then 90 days from current date
    $RefreshedFilesCount = 
        ($TotalFiles | 
            Where-Object { (New-TimeSpan -Start ($_.CommitDate) -End (Get-Date)).TotalDays -lt 90 }).Count
     Write-Output "Refreshed files: $RefreshedFilesCount"

     # count percentage
     $Refreshness = $RefreshedFilesCount / $TotalFilesCount * 100
     Write-Output "Refreshness: $Refreshness%"
}

function GetFilesFromRepo($repoPath)
{
    $currentDir = $(Get-Item -Path "./").FullName
    cd $repoPath

    $revisions = (git log --pretty="%h")
    $files = (git ls-files)
    $filesMap = @{}

    foreach ($rev in $revisions)
    {
        $revInfo = (git log --pretty="%cn,%ce,%cd,%an,%ae,%ad" --date="iso" -r $rev).Split(",")

        $commiterName = $revInfo[0]
        $commiterMail = $revInfo[1]
        $commitDate = $revInfo[2]
        $creatorName = $revInfo[3]
        $creatorMail = $revInfo[4]
        $creationDate = $revInfo[5]

        $filesInRev = (git ls-tree --name-only -r $rev)
        foreach ($file in $filesInRev)
        {
            if (-not $file.EndsWith(".md"))
            {
                continue
            }

            if (-not $filesMap.ContainsKey($file))
            {
                $fileInfo = New-Object psobject | Select-Object Name, CreatorName, creatorMail, CreationDate, CommiterName, commiterMail, CommitDate                
                $fileInfo.Name = $file
                $fileInfo.CreatorName = $creatorName
                $fileInfo.CreatorMail = $creatorMail
                $fileInfo.CreationDate = [DateTime]$creationDate
                $fileInfo.CommiterName = $commiterName
                $fileInfo.CommiterMail = $commiterMail
                $fileInfo.CommitDate = [DateTime]$commitDate

                $filesMap[$file] = $fileInfo
            }
        }
    }

    cd $currentDir
    return $filesMap.Values
}

main
