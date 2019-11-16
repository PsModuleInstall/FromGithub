
# The `install.ps1` script intended to perform direct module installation from the GitHub repo  

## 🔨 Direct download Modules instalation:

```powershell
iex ('$Module="${moduleName};$User="${Username}";$RepoName="${repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/PSModuleInstallScript/master/install.ps1'))
```

## Example ⚡:
```powershell
iex ('$Module="Bookmarks";$User="stadub";$RepoName="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/PSModuleInstallScript/master/install.ps1'))
```
