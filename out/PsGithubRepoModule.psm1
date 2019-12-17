<#
.SYNOPSIS


.DESCRIPTION
Long description

.EXAMPLE
An example

.NOTES
General notes
#>
function Install-GithubRepoModule() {
    [cmdletbinding(DefaultParameterSetName = 'RepoInfo' )]
    param (
        [Parameter(Position = 0, ParameterSetName = 'Url', ValueFromPipeline = $True, Mandatory = $true, HelpMessage="Repository/file full url")]
        [string]$Url,
    

        [Parameter(Position = 0, ParameterSetName = 'RepoInfo', Mandatory = $true, ValueFromPipelineByPropertyName  = $True, 
        HelpMessage = 'Github repo user name')]
        [Alias("GithubUser")]
        [string]$User,

        [Parameter(Position = 1, ParameterSetName = 'RepoInfo', Mandatory = $true, ValueFromPipelineByPropertyName  = $True, 
        HelpMessage = 'Repository name')]
        [Alias("Repository")]
        [string]$Repo,

        [Parameter(Position = 2, ParameterSetName = 'Positional', Mandatory=$true, ValueFromPipelineByPropertyName  = $True, 
        HelpMessage = 'Repository Folder(empty for root)')]
        [Alias("Module")]
        [AllowEmptyString()]
        [string] $ModulePath,

        [Parameter(Position = 3, ParameterSetName = 'RepoInfo', Mandatory = $false, ValueFromPipelineByPropertyName  = $True, 
        HelpMessage = 'Repository branch')]
        [AllowEmptyString()]
        [string]$Branch = "master"

    )
    . $PSScriptRoot\install.ps1
}