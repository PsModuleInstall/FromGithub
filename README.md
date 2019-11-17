
# The `install.ps1` script intended to perform direct module installation from the GitHub repo  

---------------------

## 📃 Direct download Module instalation template:

```powershell
iex ('$module="{moduleName};$user="{username}";$repo="{repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/PSModuleInstallScript/master/install.ps1'))
```

## 📘 Parameters:
`moduleName` - subfolder with module content. Live empty if the root repo folder is the module folder(contain psd1/psm1 files)

`username` - Github accout user or company name

`repoName` - user repository account



## ⚡ Example:
```powershell
iex ('$module="Bookmarks";$user="stadub";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/PSModuleInstallScript/master/install.ps1'))
```
