# To make sctipt work you should replace the next paramweter to actual repo values.

# Parameters: 
# moduleName - subfolder with module content. Live empty if the root repo folder is the module folder(contain psd1/psm1 files)
# username - Github accout user or company name
# repoName - user repository account


# Download Powershell module from gituhb 
iex ('$module="{moduleName};$user="{username}";$repo="{repoName}";'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/PsModuleInstall/InstallFromGithub/master/install.ps1'))


# Download powershell file
iex('$module="{moduleName};$user="{username}";$repo="{repoName}";$folder="$pwd";(new-object net.webclient).DownloadFile("https://raw.githubusercontent.com/$user/$repo/master/$module","$folder\$module")')
