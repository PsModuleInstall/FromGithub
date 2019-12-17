Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

# capture variable values
[string]$Url = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Url;

#[string]$FileUrl = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Url;


[string]$User = Get-Variable -ValueOnly -ErrorAction SilentlyContinue User;
[string]$Repo = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Repo;
[string]$Branch = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Branch;
[string]$ModulePath = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Module;

[string]$ModuleName = Get-Variable -ValueOnly -ErrorAction SilentlyContinue ModuleName;

[bool]$IsFile = ( Get-Variable -ValueOnly -ErrorAction SilentlyContinue IsFileScriptModule) -eq $true;

#set default values for Branch and ModulePath variables

If ( [string]::IsNullOrWhitespace($Branch) ) { $Branch = "master" }
If ( [string]::IsNullOrWhitespace($ModulePath) ) { $ModulePath = "" }

function Read-ParamMode {
    $c_url = New-Object System.Management.Automation.Host.ChoiceDescription '&Url', 'Define module repo path via repo URl'
    #$c_file_url = New-Object System.Management.Automation.Host.ChoiceDescription '&Url', 'Define powershell script file path via URl'
    $c_param = New-Object System.Management.Automation.Host.ChoiceDescription '&Params', 'Define module repo path one by one (user/repo/path)'
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($c_url, $c_param)

    $message = 'Select Module repo enter mode'
    return $host.ui.PromptForChoice($null, $message, $options, 1)
}

function Read-RepoInfo {
    param (
        [string]$DefaultUser,
        [string]$DefaultRepo,
        [string]$DefaultModulePath,
        [string]$DefaultBranch
    )

    $p_user = New-Object System.Management.Automation.Host.FieldDescription "User [$User]"
    $p_user.Label="Github user name"
    $p_user.IsMandatory=$true
    $p_user.SetParameterType([string])
    $p_user.DefaultValue = $DefaultUser
    
    $p_repo = New-Object System.Management.Automation.Host.FieldDescription "Repository [$DefaultRepo]"
    $p_repo.HelpMessage="Github Repository"
    $p_repo.SetParameterType([string])
    $p_repo.DefaultValue = $DefaultRepo

    $p_path = New-Object System.Management.Automation.Host.FieldDescription "RepoFolder (empty for root) [$DefaultModulePath]"
    $p_path.Label="Repository Folder [Live empty for root repo folder]"
    $p_path.HelpMessage="Repository Folder [Live empty for root repo folder]"
    $p_path.SetParameterType([string])
    $p_path.DefaultValue = $DefaultModulePath

    $p_branch = New-Object System.Management.Automation.Host.FieldDescription "Branch [$DefaultBranch]"
    $p_branch.HelpMessage="Repository branch [Default:master]"
    $p_branch.SetParameterType([string])
    $p_branch.DefaultValue = $DefaultBranch


    $res = $host.ui.Prompt($null,"Github Module Repository",@($p_user, $p_repo, $p_path, $p_branch))

    $c_isFile = $host.ui.PromptForChoice($null, 'Select Module type:', @("&File", "&Module Directory" ) , 1)
    $isFile = ($c_isFile -eq 0)

    If (  [string]::IsNullOrWhitespace($res[$p_user.Name]) ) {$res[$p_user.Name]=$p_user.DefaultValue} 
    If (  [string]::IsNullOrWhitespace($res[$p_repo.Name]) ) {$res[$p_repo.Name]=$p_repo.DefaultValue} 
    If (  [string]::IsNullOrWhitespace($res[$p_path.Name]) ) {$res[$p_path.Name]=$p_path.DefaultValue} 
    If (  [string]::IsNullOrWhitespace($res[$p_branch.Name]) ) {$res[$p_branch.Name]=$p_branch.DefaultValue} 


    return @{ 
        User = $res[$p_user.Name];
        Repo = $res[$p_repo.Name];
        Branch = $res[$p_branch.Name];
        ModulePath = $res[$p_path.Name];
        IsFile = $isFile;
    }
}

function Get-LocalTempPath {
    param (
        [string] $RepoName
    )
    $tmpDir = [System.IO.Path]::GetTempPath();
    return "$tmpDir\$RepoName";
}

function Get-ModuleInstallFolder {
    param (
        [string] $ModuleName
    )

    $separator = [IO.Path]::PathSeparator;

    $ProfileModulePath = $env:PSModulePath.Split($separator)[0];
    if (!(Test-Path $ProfileModulePath)) {
        New-Item -ItemType Directory -Path $ProfileModulePath;
    }

    $pathToInstal = Join-Path $ProfileModulePath $ModuleName;


    if (Test-Path $pathToInstal) {
        Write-Warning "Directory with the name '$ModuleName' alredy exist in the Profile directory ''$ProfileModulePath''.";

        $c_yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes', 'Yes'
        $c_no = New-Object System.Management.Automation.Host.ChoiceDescription '&No', 'No'
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($c_yes, $c_no)

        $result =  $host.ui.PromptForChoice($null, 'Do you totally sure you want to download module?', $options, 1)

        switch ($result)
        {
            0 { }
            1 { throw  "Unable to install module '$ModuleName'. 
                Please rename the exisitng module folder and try again."; }
        }
    }
    return $pathToInstal;
}

function Receive-Module {
    param (
        [string]$User,
        [string]$Repo,
        [string]$Branch,
        [string]$File
    )

    $Url = [uri]"https://github.com/${User}/${Repo}/archive/${Branch}.zip";

    $client = New-Object System.Net.WebClient;
    try {

        $progressEventArgs = @{
            InputObject = $client
            EventName = 'DownloadProgressChanged'
            SourceIdentifier = 'ModuleDownload'
            Action = {
                
                Write-Progress -Activity "Module Installation" -Status `
                ("Downloading Module: {0} of {1}" -f $eventargs.BytesReceived, $eventargs.TotalBytesToReceive) `
                -PercentComplete $eventargs.ProgressPercentage 
            }
        };

        $completeEventArgs = @{
            InputObject = $client
            EventName = 'DownloadFileCompleted'
            SourceIdentifier = 'ModuleDownloadCompleted'
        };

        Register-ObjectEvent @progressEventArgs;
        Register-ObjectEvent @completeEventArgs;
        

        $client.DownloadFileAsync($Url, $File);

        Wait-Event -SourceIdentifier ModuleDownloadCompleted;
    }
    catch [System.Net.WebException]  
    {  
        Write-Host("Cannot download $Url");
    } 
    finally {
        $client.dispose();
        Unregister-Event -SourceIdentifier ModuleDownload;
        Unregister-Event -SourceIdentifier ModuleDownloadCompleted;

        Write-Debug "Unblock downloaded file access $File";
        Unblock-File -Path $File;
    }

}

function Expand-ModuleZip {
    param (
        [string] $Archive,
        [string] $Module,
        [string] $DestFolder,
        [bool] $IsFile
    )

    #avoid errors on already existing file
    try {

        Write-Progress -Activity "Module Installation"  -Status "Unpack Module" -PercentComplete 0;
        
        Write-Debug "Unzip file to floder $Archive";


        Add-Type -AssemblyName System.IO.Compression.FileSystem;
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Archive);

        $baseDir = $zip.Entries[0].FullName;
        $modulePath = $baseDir + $Module;
        $slash = [System.IO.Path]::DirectorySeparatorChar;

        if($IsFile){
            $entry = $zip.GetEntry($modulePath);

            if( -not (Test-Path $DestFolder)){
                New-Item -path $DestFolder -ItemType Directory;
            }

            $destinationPath = $DestFolder + $slash + $entry.Name;
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true);
            return;
        }

        foreach ($entry in $zip.Entries) {
            if($entry.FullName.StartsWith($modulePath, [StringComparison]::OrdinalIgnoreCase))
            {
                $relativePath = $entry.FullName.Split($modulePath)[1]
                $relativePath = $relativePath.Replace('/',$slash)

                # Gets the full path to ensure that relative segments are removed.
                $destinationPath = $DestFolder + $relativePath;

                if([string]::IsNullOrWhiteSpace($entry.Name)){
                    if( -not (Test-Path $destinationPath)){
                        New-Item -path $destinationPath -ItemType Directory;
                    }
                }
                else{
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true);
                }
            }
        }

    }
    catch 
    {  
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        throw;
    } 
    finally{
        if( $null -ne $zip){
            $zip.Dispose();
        }
    }

    Write-Progress -Activity "Module Installation"  -Status "Unpack Module" -PercentComplete 40;
}

function Move-ModuleFiles {
    param (
        [string] $ArchiveFolder,
        [string] $Module,
        [string] $Branch,
        [string] $DestFolder
    )
    if ( -not (Test-Path $DestFolder) ){
        New-Item $DestFolder -type directory
    }

    $path = Resolve-Path -Path "${ArchiveFolder}\*-$Branch\$Module"
    
    Write-Progress -Activity "Module Installation"  -Status "Copy Module to PowershellModules folder" -PercentComplete 50;
    Move-Item -Path "$($path.Path)\*" -Destination "$DestFolder";
    Write-Progress -Activity "Module Installation"  -Status "Copy Module to PowershellModules folder" -PercentComplete 60;
}

function Invoke-Cleanup{
    param (
        [string] $Archive
    )
    Write-Progress -Activity "Module Installation"  -Status "Finishing Installation and Cleanup " -PercentComplete 80;
    Remove-Item "${Archive}" -Recurse -ErrorAction SilentlyContinue;
    Write-Progress -Activity "Module Installation"  -Status "Module installed sucessaful";
}


function Write-Finish {
    param (
        [string] $moduleName
    )
    Write-Host "Module installation complete";

    Write-Host "Tupe ''Import-Module $moduleName'' to start using module";

}



function GetGroupValue($match, [string]$group, [string]$default = "") {
    $val = $match.Groups[$group].Value
    Write-Debug $val
    if ($val) {
        return $val
    }
    return $default
}

function Convert-GitHubUrl(){
    param (
        [string]$Url
    )
    
    $githubUriRegex = "(?<Scheme>https://)(?<Host>github.com)/(?<User>[^/]*)/(?<Repo>[^/]*)((?<IsFile>/tree/|/blob/)(?<Branch>[^/]*)(/(?<Folder>.*))?)?(/archive/(?<Branch>.*).zip)?";

    $githubMatch = [regex]::Match($Url, $githubUriRegex);

    if ( ! $(GetGroupValue $githubMatch "Host") ) {
        throw [System.ArgumentException] "Incorrect 'Host' value. The 'github.com' domain expected";
        #Write-Error -Message "Incorrect 'Host' value. The 'github.com' domain expected" -Category InvalidArgument
    }
    return @{ 
        User = GetGroupValue $githubMatch "User";
        Repo = GetGroupValue $githubMatch "Repo";
        Branch = GetGroupValue $githubMatch "Branch" "master";
        ModulePath = GetGroupValue $githubMatch "Folder";
        IsFile = ((GetGroupValue $githubMatch "IsFile") -eq '/blob/');
    }
}

function Get-CommitInfo {
    param (
        [string]$User,
        [string]$Repo
    )
    $restInfoUrl = [uri]"https://api.github.com/repos/${User}/${Repo}/commits";

    $json = Invoke-WebRequest $restInfoUrl | Select-Object  -ExpandProperty Content | ConvertFrom-Json

    return @{
        Date = $json[0].commit.author.date;
        Author = $json[0].commit.author.name;
        Message = $json[0].commit.message;
        Hash = $json[0].sha;
    }
}


function Get-StringHash {
    param (
        [string]$text
    )
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider;
    return $md5.ComputeHash( [System.Text.Encoding]::UTF8.GetBytes( $text ) );
    
}

function New-GeneratedManifest {
    param (

        [string]$Guid,

        [string]$ModuleName,
        [string]$Version,
        [string]$ReleaseNotes,

        [string]$User,
        [string]$Repo,
        [string]$ModulePath,
        [string]$Branch,
        [string[]]$ScriptFiles,
        [string]$MainfestFile
    )
    $moduleUrl ="https://github.com/${User}/${Repo}/tree/${Branch}/${ModulePath}";
    $LicenseUri = "https://github.com/${User}/${Repo}/blob/master/LICENSE"
   

    $moduleSettings = @{
        ModuleVersion = $Version;
        GUID = $Guid
        Author  = $User
        Copyright  = "(c) $User. All rights reserved."
        CmdletsToExport = '*'
        NestedModules = $ScriptFiles
        FunctionsToExport = '*'
        VariablesToExport = @()
        AliasesToExport = @()
       
        HelpInfoURI = $moduleUrl
    }

    New-ModuleManifest @moduleSettings -Path $MainfestFile -LicenseUri $LicenseUri -ProjectUri  $moduleUrl -ReleaseNotes  $ReleaseNotes

}

# in case when both Url and Repo variables are empty - request params in the interactive mode
if ( "x$Url" -eq "x" -and "x$Repo" -eq "x" ) { #-and "x$FileUrl" -eq "x" ) {

    $result = Read-ParamMode
    switch ($result)
    {
        0 {
            $result = $host.ui.Prompt($null,$null,"Github Module Url");
            $Url = $result[$result.keys[0]];
        }
        1 { 
            $repoInfo = Read-RepoInfo -DefaultUser $User -DefaultRepo $Repo -DefaultModulePath $ModulePath  -DefaultBranch $Branch
            $User = $repoInfo['User'];
            $Repo = $repoInfo['Repo'];
            $Branch = $repoInfo['Branch'];
            $ModulePath = $repoInfo['ModulePath'];
            $IsFile = $repoInfo['IsFile'];
        }
    }
}

# try convert url to fully cvalified path
if( -not [string]::IsNullOrWhitespace($Url) ){
    $res = Convert-GitHubUrl -Url $Url
    $User = $res['User'];
    $Repo = $res['Repo'];
    $Branch = $res['Branch'];
    $ModulePath = $res['ModulePath'];
    $IsFile = $res['IsFile'];
}

if( -not ([string]::IsNullOrWhitespace($ModulePath)) ){
    ##remove fiew name line number and starting slash
    $moduleToLoad = $ModulePath.TrimStart('/').Split("#")[0] 
    $moduleName = Split-Path $moduleToLoad -leaf;
    
}
else{
    $moduleName = $Repo;
    $moduleToLoad = "";
}

#for file modules remove file extension 
if( $IsFile ){
    $moduleName =  Split-Path $moduleName -LeafBase
}

if( ([string]::IsNullOrWhitespace($Branch)) ){
    $Branch = "master";
}

$host.ui.WriteLine([ConsoleColor]::Green, [ConsoleColor]::Black, "Start downloading Module ${moduleName} from GitHub Repository:${Repo} User:${User} Branch:${Branch}")

$tempFile = Get-LocalTempPath -RepoName $Repo;
$moduleFolder = Get-ModuleInstallFolder -ModuleName $moduleName;

$archiveFile =  "${tempFile}.zip";

Receive-Module -User $User -Repo $Repo -Branch $Branch -File $archiveFile;

$res  = Get-CommitInfo -Repo $Repo -User $User

$date = $res['Date'];
#$author = $res['Author'];
$message = $res['Message'];
$commitHash = $res['Hash'];

#create datetime based module version folder
$datedVersion = $date.ToString("yy.MM.ddHH.mmss")
$moduleFolder += "\$datedVersion"

Expand-ModuleZip -Archive $archiveFile -Module $moduleToLoad -DestFolder $moduleFolder -IsFile $IsFile

#Move-ModuleFiles -ArchiveFolder $archiveName -Branch $Branch -Module $moduleToLoad -DestFolder $moduleFolder;


Write-Progress -Activity "Module Installation"  -Status "Store computed moduel hash" -PercentComplete 40;

Out-File -InputObject $commitHash -FilePath "$moduleFolder\hash" 


#if the manifest file is apsent - try to generate a new one
if( ! (Test-Path "$moduleFolder\*.psd1") ){



    $identity = $User+$Repo+$moduleName
    [byte[]]$hash = Get-StringHash -Text $identity;

    $module_uid = (New-Object Guid @(,$hash)).ToString();

    $psFiles = Get-ChildItem "$moduleFolder/*.ps1" | Select-Object  -ExpandProperty Name

    $mainfestFile = "${moduleFolder}\${moduleName}.psd1"
    New-GeneratedManifest -Guid $module_uid -ModuleName $moduleName -Version $datedVersion -ReleaseNotes $message -User $User -Repo $Repo -ModulePath $moduleToLoad -Branch $Branch  -ScriptFiles $psFiles -MainfestFile $mainfestFile
}

Invoke-Cleanup -Archive $archiveFile 

Write-Finish -moduleName $moduleName
