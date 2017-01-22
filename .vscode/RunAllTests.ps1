Import-Module (Join-Path $PSScriptRoot "..\Tests\xStorage.TestHarness.psm1" -Resolve)
$dscTestsPath = Join-Path -Path $PSScriptRoot `
                    -ChildPath "..\Modules\xStorage\DscResource.Tests\Meta.Tests.ps1"
Invoke-xStorageTest -DscTestsPath $dscTestsPath
