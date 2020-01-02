<#
    .DESCRIPTION

    Depack an APK using APKTOOL instance present in PATH environment variable.

    .PARAMETER apkLocation

    Path to the APK to depack.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The function return the output of the tools used.    

    .EXAMPLE

    PS> Expand-APK -apkLocation app.apk
#>
function Expand-APK {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $apkLocation
    )
    Write-Host "Depacking '$apkLocation' file to folder 'out'..." -ForegroundColor Green
    Remove-Item "out" -Recurse -ErrorAction Ignore
    apktool d $apkLocation -o out/
}

<#
    .DESCRIPTION

    Repack and sign an APK using APKTOOL + APKSIGNER instances present in PATH environment variable.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The function return the output of the tools used.        

    .EXAMPLE

    PS> Compress-APK   
#>
function Compress-APK {
    $keystoreLocation = (Get-Module -ListAvailable Android-Utils).path
    $keystoreLocation = $keystoreLocation.Replace("Android-Utils.psm1", "my.keystore")
    Write-Host "Repacking folder 'out' to 'app-updated.apk' file using keystore '$keystoreLocation'..." -ForegroundColor Green
    Remove-Item app-updated.apk -Recurse -ErrorAction Ignore
    apktool b -d out/ -o app-updated.apk
    apksigner sign --ks $keystoreLocation --ks-pass pass:mypass app-updated.apk
}

<#
    .DESCRIPTION

    Re-Install patched application using the current connected ADB instance.

    .PARAMETER appPkg

    Package name of the application.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The function return the output of the tools used.        

    .EXAMPLE

    PS> Install-APK -appPkg my.app.package     
#>
function Install-APK {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $appPkg
    )
    Write-Host "Uninstall the current application version..." -ForegroundColor Green
    adb uninstall $appPkg
    Write-Host "Install the patched application version..." -ForegroundColor Green
    adb install app-updated.apk
}

<#
    .DESCRIPTION

    Check availability of used Android tools.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The function return the output of the tools used.        

    .EXAMPLE

    PS> Test-Tools   
#>
function Test-Tools {
    Write-Host "Ensure that the following Android SDK folders are added to the PATH environment variable:" -ForegroundColor Cyan 
    Write-Host "- [SDK_HOME]\platform-tools"
    Write-Host "- [SDK_HOME]\build-tools\[LAST_INSTALLED_VERSION_FOLDER]"
    Write-Host "- [SDK_HOME]\tools"    
    Write-Host "- [SDK_HOME]\tools\bin"
    Write-Host "Current version of Android tools:" -ForegroundColor Green    
    Write-Host "ADB (https://developer.android.com/studio#downloads):" -ForegroundColor Yellow
    adb --version
    Write-Host "APKSIGNER (https://developer.android.com/studio#downloads):" -ForegroundColor Yellow
    apksigner --version
    Write-Host "APKTOOL (https://bitbucket.org/iBotPeaches/apktool/downloads):" -ForegroundColor Yellow
    apktool --version
}

<#
    .DESCRIPTION

    List installed packages on current connected device using the current connected ADB instance.

    .EXAMPLE

    PS> Get-Packages    
#>
function Get-Packages {
    Write-Host "List current installed packages..." -ForegroundColor Green
    adb shell pm list packages
}

<#
    .DESCRIPTION

    Get the APK from the provided package name on current connected device using the current connected ADB instance.

    .PARAMETER appPkg

    Package name of the application.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The function return the output of the tools used.        

    .EXAMPLE

    PS> Get-APK -appPkg my.app.package  
#>
function Get-APK {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $appPkg
    )
    Write-Host "Get APK for the path '$appPkg'..." -ForegroundColor Green
    $pkgPath = adb shell pm path $appPkg
    $pkgPath = $pkgPath.Replace("package:", "")
    Remove-Item app.apk -Recurse -ErrorAction Ignore
    adb pull "$pkgPath" app.apk
    Write-Host "APK stored as 'app.apk' file"
}

<#
    .DESCRIPTION

    Show the device log applying the provided filter on current connected device using the current connected ADB instance.

    .PARAMETER marker

    Filtering expression used as string and not as regex.   

    .PARAMETER tag

    Filtering expression used as Android logging TAG.

    .PARAMETER priority

    Filtering log priority ordered from lowest to highest priority (single character in the following range):
    (V)erbose / (D)ebug / (I)nfo / (W)arning / (E)rror / (F)atal / (S)ilent.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The function return the output of the tools used.        

    .EXAMPLE

    PS> Watch-Log -marker "Wifi"     

    .EXAMPLE

    PS> Watch-Log -tag "APP_TAG"         

    .EXAMPLE

    PS> Watch-Log -tag "APP_TAG" -priority I            

    .EXAMPLE

    PS> Watch-Log -priority I  
    
    .LINK
    
    https://developer.android.com/studio/command-line/logcat#filteringOutput    
#>
function Watch-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]
        $marker,
        [Parameter(Mandatory = $false)]
        [String]
        $tag,        
        [Parameter(Mandatory = $false)]        
        [ValidateSet("V", "D", "I", "W", "E", "F", "S")]
        [String]
        $priority        
    )
    $filter = ""
    if ($marker) {
        $filter += "-e `"$marker`""
    }   
    if ($tag -and $priority) {
        $filter += " ${tag}:${priority} *:S"
    } 
    elseif ($priority) {
        $filter += " *:${priority}"
    }
    elseif ($tag) {
        $filter += " ${tag}:V *:S"
    }
    $filter = $filter.Trim() 
    Write-Host "Apply filter (https://developer.android.com/studio/command-line/logcat): '$filter'" -ForegroundColor Green
    adb logcat -v color $filter
}

# Define exported functions
Export-ModuleMember -Function *
