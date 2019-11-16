
# The `install.ps1` script intended to perform direct module installation from the GitHub repo  

## 🔨 Direct download Modules instalation:

```powershell
iex ('$module="${moduleName};$user="${Username}";$repo="${repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/PSModuleInstallScript/master/install.ps1'))
```

## Example ⚡:
```powershell
iex ('$module="Bookmarks";$user="stadub";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/PSModuleInstallScript/master/install.ps1'))
```
