# Powershell module GitHub installer
 
This repository contain script intendend to download Powershell module directly from the GitHub repo

Powershell module path can be set in one of the next ways:

1. Module GitHub UserName, Repository, Branch(not required), Folder(optional)
1. Github Folder Url
2. Interactive mode

### GitHub Powershell Module parameters

* `moduleName` - subfolder with module content. Live empty if the root repo folder is the module folder(contain psd1/psm1 files)

* `username` - Github accout user or company name

* `repoName` - user repository account

#### Script Template

```powershell
iex ('$module="{moduleName}";$user="{username}";$repo="{repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```

#### Example: Downloading `Bookmarks` module from `PowershellScripts` repo

```powershell
iex ('$module="Bookmarks";$user="stadub";$repo="PowershellScripts";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```

### GitHub Powershell Module Url

* `url` - url to the repo-folder

#### Script Template

```powershell
iex ('$url="{url}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
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

Interactive mode represents one of modes defined above.
But allow to fill in info in wizard mode 


```powershell
iex('(new-object net.webclient).DownloadString("https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1")')
```

<!-- ---------------------

### Script file download

For the cases when he module represent only one file it can be downloaded directly.

Direct download script file: 

```powershell
'(new-object net.webclient).DownloadString("https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1")'

``` -->
