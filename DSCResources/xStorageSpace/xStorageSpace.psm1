$DSCResources = @( Get-ChildItem -Path $PSScriptRoot\DSCResources\*.ps1 -Exclude *.tests.ps1 -ErrorAction SilentlyContinue )

Export-ModuleMember -Function $DSCResources.Basename