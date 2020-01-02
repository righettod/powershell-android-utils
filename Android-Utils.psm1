<#
    .Description
    Depack an APK using APKTOOL instance present in PATH environment variable.

    .Parameter apkLocation
    Path to the APK to depack.
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
    .Description
    Repack and sign an APK using APKTOOL + APKSIGNER instances present in PATH environment variable.
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
    .Description
    Re-Install patched application using the current connected ADB instance.

    .Parameter appPkg
    Package name of the application.
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
    .Description
    Check availability of used Android tools.
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
    .Description
    List installed packages on current connected device using the current connected ADB instance.
#>
function Get-Packages {
    Write-Host "List current installed packages..." -ForegroundColor Green
    adb shell pm list packages
}

<#
    .Description
    Get the APK from the provided package name on current connected device using the current connected ADB instance.

    .Parameter appPkg
    Package name of the application.
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
    .Description
    Show the device log applying the provided filter on current connected device using the current connected ADB instance.

    .Parameter marker
    Filtering expression used as string and not as regex.   

    .Parameter tag
    Filtering expression used as Android logging TAG.

    .Parameter priority
    Filtering log priority ordered from lowest to highest priority: 
    (V)erbose / (D)ebug / (I)nfo / (W)arning / (E)rror / (F)atal / (S)ilent.
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
