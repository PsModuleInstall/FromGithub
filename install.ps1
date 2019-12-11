# capture variable values
[string]$Url = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Url;
[string]$User = Get-Variable -ValueOnly -ErrorAction SilentlyContinue User;
[string]$Repo = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Repo;
[string]$Branch = Get-Variable -ValueOnly -ErrorAction SilentlyContinue Branch;

#set default values for Branch and ModulePath variables
$Branch =  ({"master"}, {$Branch} )[ "x$Branch"-eq "x" ]
$ModulePath =  ({""}, {$ModulePath} )[ "x$ModulePath"-eq "x" ]



function Read-ParamMode {
    $c_url = New-Object System.Management.Automation.Host.ChoiceDescription '&Url', 'Define module repo path via repo URl'
    $c_param = New-Object System.Management.Automation.Host.ChoiceDescription '&Params', 'Define module repo path one by one (user/repo/path)'
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($c_url, $c_param)

    $message = 'Select Module repo enter mode'
    return $host.ui.PromptForChoice($null, $message, $options, 1)
}

function Read-RepoInfo {
    param (
        [string]$User,
        [string]$Repo,
        [string]$ModulePath,
        [string]$Branch
    )
    $p_user = New-Object System.Management.Automation.Host.FieldDescription 'User ['+$User+']'
    $p_user.Label="Github user name"
    $p_user.IsMandatory=$true
    $p_user.SetParameterType([string])
    $p_user.DefaultValue = $User
    
    $p_repo = New-Object System.Management.Automation.Host.FieldDescription 'Repository ['+$Repo+']'
    $p_repo.HelpMessage="Github Repository"
    $p_repo.SetParameterType([string])
    $p_user.DefaultValue = $Repo

    $p_path = New-Object System.Management.Automation.Host.FieldDescription 'RepoFolder (empty for root) [' +$ModulePath +']'
    $p_path.Label="Repository Folder [Live empty for root repo folder]"
    $p_path.HelpMessage="Repository Folder [Live empty for root repo folder]"
    $p_path.SetParameterType([string])
    $p_path.DefaultValue = $ModulePath

    $p_branch = New-Object System.Management.Automation.Host.FieldDescription 'Branch ['+$Branch+']'
    $p_branch.HelpMessage="Repository branch [Default:master]"
    $p_branch.SetParameterType([string])
    $p_branch.DefaultValue = $Branch


    $res = $host.ui.Prompt($null,"Github Module Repository",@($p_user, $p_repo, $p_path, $p_branch))

    If ( ! [string]::IsNullOrWhitespace($res[$p_user.Name]) ) { $res[$p_user.Name] } Else {$res[$p_user.Name]=$p_user.DefaultValue} 
    If ( ! [string]::IsNullOrWhitespace($res[$p_repo.Name]) ) { $res[$p_repo.Name] } Else {$res[$p_repo.Name]=$p_repo.DefaultValue} 
    If ( ! [string]::IsNullOrWhitespace($res[$p_path.Name]) ) { $res[$p_path.Name] } Else {$res[$p_path.Name]=$p_path.DefaultValue} 
    If ( ! [string]::IsNullOrWhitespace($res[$p_branch.Name]) ) { $res[$p_branch.Name] } Else {$res[$p_branch.Name]=$p_branch.DefaultValue} 

    return @{
        User = $res[$p_user.Name]
        Repo = $res[$p_repo.Name]
        Branch = $res[$p_branch.Name]
        ModulePath = $res[$p_path.Name]
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
        throw "Unable to install module ''$ModuleName''. 
        Directory with the same name alredy exist in the Profile directory ''$ProfileModulePath''.
        Please rename the exisitng module folder and try again. 
        ";
    }
    return $pathToInstal;
}

function Receive-Module {
    param (
        [string] $File,
        [string] $Url
    )
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
    }
}

function Expand-ModuleZip {
    param (
        [string] $Archive
    )

    #avoid errors on already existing file
    try {
        Write-Debug "Unblock downloaded file access $Archive";
        Unblock-File -Path "${Archive}.zip";

        Write-Progress -Activity "Module Installation"  -Status "Unpack Module" -PercentComplete 0;
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem;
        Write-Debug "Unzip file to floder $Archive";
        [System.IO.Compression.ZipFile]::ExtractToDirectory("${Archive}.zip", "${Archive}");
    }
    catch {  }

    Write-Progress -Activity "Module Installation"  -Status "Unpack Module" -PercentComplete 40;
}

function Move-ModuleFiles {
    param (
        [string] $ArchiveFolder,
        [string] $Module,
        [string] $DestFolder,
        [string] $ModuleHash
    )

    Write-Progress -Activity "Module Installation"  -Status "Store computed moduel hash" -PercentComplete 40;
    Out-File -InputObject $ModuleHash -Path "${ArchiveFolder}\*-master\$Module\hash" 
    
    Write-Progress -Activity "Module Installation"  -Status "Copy Module to PowershellModules folder" -PercentComplete 50;
    Move-Item -Path "${ArchiveFolder}\*-master\$Module" -Destination "$DestFolder";
    Write-Progress -Activity "Module Installation"  -Status "Copy Module to PowershellModules folder" -PercentComplete 60;
}

function Invoke-Cleanup{
    param (
        [string] $ArchiveFolder
    )
    Write-Progress -Activity "Module Installation"  -Status "Finishing Installation and Cleanup " -PercentComplete 80;
    Remove-Item "${ArchiveFolder}*" -Recurse -ErrorAction SilentlyContinue;
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
    
    $githubUriRegex = "(?<Scheme>https://)(?<Host>github.com)/(?<User>[^/]*)/(?<Repo>[^/]*)(/tree/(?<Branch>[^/]*)(/(?<Folder>.*))?)?(/archive/(?<Branch>.*).zip)?";

    $githubMatch = [regex]::Match($Url, $githubUriRegex);

    if ( ! $(GetGroupValue $githubMatch "Host") ) {
        throw [System.ArgumentException] "Incorrect 'Host' value. The 'github.com' domain expected";
        #Write-Error -Message "Incorrect 'Host' value. The 'github.com' domain expected" -Category InvalidArgument
    }
    return @{ 
        User = GetGroupValue $githubMatch "User"
        Repo = GetGroupValue $githubMatch "Repo"
        Branch = GetGroupValue $githubMatch "Branch" "master"
        ModulePath = GetGroupValue $githubMatch "Folder"
    }
}


# in case when both Url and Repo variables are empty - request params in the interactive mode
if ( "x$Url" -eq "x" -and "x$Repo" -eq "x" ) {

    $result = Read-ParamMode
    switch ($result)
    {
        0 {
            $Url = $host.ui.Prompt($null,$null,"Github Module Url")
        }
        1 { 
            $res = Read-RepoInfo -User $User -Repo $Repo -ModulePath $ModulePath  -Branch $Branch
            $User = $res['User'];
            $Repo = $res['Repo'];
            $Branch = $res['Branch'];
            $ModulePath = $res['ModulePath'];
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
}

if( -not ([string]::IsNullOrWhitespace($ModulePath)) ){
    $moduleToLoad = $ModulePath;
    $moduleName = Split-Path $moduleToLoad -leaf;
    
}
else{
    $moduleName = $Repo;
    $moduleToLoad = "";
}

if( ([string]::IsNullOrWhitespace($Branch)) ){
    $Branch = "master";
}

$tempFile = Get-LocalTempPath -RepoName $Repo;
$moduleFolder = Get-ModuleInstallFolder -ModuleName $moduleName;

$downloadUrl = [uri]"https://github.com/${User}/${Repo}/archive/${Branch}.zip";

$file =  "${tempFile}.zip";

Receive-Module -Url $downloadUrl -File $file;

$moduleHash = Get-FileHash -Algorithm SHA384 -Path $file

$archiveName = $tempFile;

Expand-ModuleZip -Archive $archiveName;

Move-ModuleFiles -ArchiveFolder $archiveName -Module $moduleToLoad -DestFolder $moduleFolder;
Invoke-Cleanup -ArchiveFolder $archiveName

Write-Finish -moduleName $moduleName
