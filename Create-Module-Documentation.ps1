# Create required elements
cd docs
$cdir=Get-Location
Remove-Item Invoke-CreateModuleHelpFile.ps1 -ErrorAction Ignore -Force
Remove-Item modules -ErrorAction Ignore -Force  -Recurse
New-Item -Path "." -Name "modules" -ItemType "directory"
New-Item -Path "modules" -Name "Android-Utils" -ItemType "directory"
Copy-Item "..\Android-Utils.psm1" -Destination ".\modules\Android-Utils"
Copy-Item "..\Android-Utils.psd1" -Destination ".\modules\Android-Utils"
wget "https://raw.githubusercontent.com/righettod/Invoke-CreateModuleHelpFile/master/Invoke-CreateModuleHelpFile.ps1" -outfile "Invoke-CreateModuleHelpFile.ps1"
# Generate the documentation HTML file
Get-ChildItem -Path . -Recurse -Depth 5
. .\Invoke-CreateModuleHelpFile.ps1
Import-Module -Name .\modules\Android-Utils
Invoke-CreateModuleHelpFile -ModuleName "Android-Utils" -Path "$cdir\index.html"
# Post generation cleanup
Remove-Item Invoke-CreateModuleHelpFile.ps1 -ErrorAction Ignore -Force
Remove-Item modules -ErrorAction Ignore -Force  -Recurse
