This repository contain script intendend to download Powershell module directly from the GitHub repo

Next instalation modes are currently supported:

* Script mode with predifined repo values
* Interactive mode

## Script Mode

Can be set ether Github Url or Repo/Username/Branch/Folder

### RepoPath Parameters

* `moduleName` - subfolder with module content. Live empty if the root repo folder is the module folder(contain psd1/psm1 files)

* `username` - Github accout user or company name

* `repoName` - user repository account

#### Script Templates

```powershell
iex ('$module="{moduleName}";$user="{username}";$repo="{repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```

#### Example: Downloading `Bookmarks` module from `PowershellScripts` repo

```powershell
iex ('$module="Bookmarks";$user="stadub";$repo="PowershellScripts";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```

### Repository folder Url

* `url` - url to the repo-folder

```powershell
iex ('$url="{url}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```

#### Example: Downloading `7Zip` module by url from `PowershellScripts` repo `7-Zip-Release-1.1` branch

```powershell
iex ('$url="https://github.com/stadub/PowershellScripts/tree/7-Zip-Release-1.1/7Zip";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```

## Interactive mode

```powershell
iex(iex('(new-object net.webclient).DownloadString("https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1")'))
```

<!-- ---------------------

### Script file download

For the cases when he module represent only one file it can be downloaded directly.

Direct download script file: 

```powershell
'(new-object net.webclient).DownloadString("https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1")'

``` -->