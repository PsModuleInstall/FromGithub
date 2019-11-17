
This repository contain script allows to download module directly from the GitHub repo

---------------------


### Downloading module from Github repository

Parameters:
* `moduleName` - subfolder with module content. Live empty if the root repo folder is the module folder(contain psd1/psm1 files)

* `username` - Github accout user or company name

* `repoName` - user repository account

```powershell
iex ('$module="{moduleName};$user="{username}";$repo="{repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```


Example: Downloading `Bookmarks` module from `PowershellScripts` repo
```powershell
iex ('$module="Bookmarks";$user="stadub";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))
```


### Direct download script file: 

For the cases when he module represent only one file it can be downloaded directly.

Direct download script file: 

Parameters:
* `moduleName` - subfolder with module content. Live empty if the root repo folder is the module folder(contain psd1/psm1 files)

* `username` - Github accout user or company name

* `repoName` - user repository account

```powershell
iex('$module="{moduleName};$user="{username}";$repo="{repoName}";$folder="$pwd";(new-object net.webclient).DownloadFile("https://raw.githubusercontent.com/$user/$repo/master/$module","$folder\$module")')
```

Example: Downloading `install.ps1` script 
```powershell
iex('$user="PsModuleInstall";$repo="InstallFromGithub";$module="install.ps1";$folder="$pwd";(new-object net.webclient).DownloadFile("https://raw.githubusercontent.com/$user/$repo/master/$module","$folder\$module")')
```
