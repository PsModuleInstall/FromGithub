[cmdletbinding(DefaultParameterSetName = 'RepoInfo' )]
param (
    [Parameter(Position = 0, ParameterSetName = 'Url', ValueFromPipeline = $True, Mandatory = $true)]
    [string]$Url,
  

    [Parameter(Position = 0, ParameterSetName = 'RepoInfo', Mandatory = $true, ValueFromPipelineByPropertyName  = $True, 
    HelpMessage = 'Github user name')]
    [Alias("GithubUser")]
    [string]$User,

    [Parameter(Position = 1, ParameterSetName = 'RepoInfo', Mandatory = $true, ValueFromPipelineByPropertyName  = $True, 
    HelpMessage = 'Repository name')]
    [Alias("Repository")]
    [string]$Repo,

    [Parameter(Position = 2, ParameterSetName = 'Positional', Mandatory=$false, ValueFromPipelineByPropertyName  = $True, 
    HelpMessage = 'Repository Folder')]
    [Alias("Module")]
    [string] $ModulePath = "",

    [Parameter(Position = 3, ParameterSetName = 'RepoInfo', Mandatory = $false, ValueFromPipelineByPropertyName  = $True, 
    HelpMessage = 'Repository branch')]
    [string]$Branch = "master"

)

function FunctionName {
    
    #check params
    if( [string]::IsNullOrWhitespace( $GithubUser) ){
        $user = $GithubUser;
    }

    #check params
    if( [string]::IsNullOrWhitespace( $GithubUser) ){
        $user = $GithubUser;
    }

    if( [string]::IsNullOrWhitespace( $Repository) ){
        $repo = $Repository;
    }

    if( [string]::IsNullOrWhitespace( $ModulePath) ){
        $module = $ModulePath;
    }

    # check variables
    $module="{moduleName}";$user="{username}";$repo="{repoName}"

    if( [string]::IsNullOrWhitespace( $repo) ){
        $repo = $repo;
    }

    if ( Test-Path variable:moduleName ){
        $user = $GithubUser;
    }


    if ( Test-Path variable:moduleName ){
        $module = $moduleName;
    }
    $module="{moduleName}";$user="{username}";$repo="{repoName}"

    if(Test-Path variable:repoName){
        $repo = $repoName;
    }
    if(Test-Path variable:module){
        $module = $modulePath;
    }

    # convert values
    if( -not ([string]::IsNullOrWhitespace($module)) ){
        $moduleToLoad = $module;
        $moduleName = Split-Path $moduleToLoad -leaf;
        
    }
    else{
        $moduleName = $repoName;
        $moduleToLoad = "";
    }
}

function Get-SavePath {
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

function Move-ModuleAndFinish {
    param (
        [string] $ArchiveFolder,
        [string] $Module,
        [string] $DestFolder
    )


    
    Write-Progress -Activity "Module Installation"  -Status "Copy Module to PowershellModules folder" -PercentComplete 50;
    Move-Item -Path "${ArchiveFolder}\*-master\$Module" -Destination "$DestFolder";
    Write-Progress -Activity "Module Installation"  -Status "Copy Module to PowershellModules folder" -PercentComplete 60;

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


$tempFile = Get-SavePath -RepoName $Repo;
$moduleFolder = Get-ModuleInstallFolder -ModuleName $moduleName;

$downloadUrl = [uri]"https://github.com/${User}/${Repo}/archive/${Branch}.zip";

$file =  "${tempFile}.zip";

Receive-Module -Url $downloadUrl -File $file;

$archiveName = $tempFile;

Expand-ModuleZip -Archive $archiveName;

Move-ModuleAndFinish -ArchiveFolder $archiveName -Module $moduleToLoad -DestFolder $moduleFolder;

Write-Finish -moduleName $moduleName