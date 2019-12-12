$newstreamreader = New-Object System.IO.StreamReader(".\install.ps1")
$in = $newstreamreader.ReadToEnd()
$newstreamreader.Dispose()

Invoke-Expression ('$module="Bookmarks";$user="stadub";$repo="PowershellScripts";'+$in)