<#
    .DESCRIPTION

    Show the APK signature using APKSIGNER instance present in PATH environment variable.

    .PARAMETER apkLocation

    Path to the APK for which the signature must be displayed.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The signature information.    

    .EXAMPLE

    PS> Show-Signature-AP -apkLocation app.apk
	
    .LINK
    
    https://source.android.com/security/apksigning
#>
function Show-Signature-APK {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $apkLocation
    )
    Write-Host "Signature of the file '$apkLocation':" -ForegroundColor Green
    apksigner verify --verbose --print-certs $apkLocation
}

<#
    .DESCRIPTION

    Depack an APK using APKTOOL instance present in PATH environment variable.

    .PARAMETER apkLocation

    Path to the APK to depack.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.    

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

    Repack and sign an APK using APKTOOL + ZIPALIGN + APKSIGNER instances present in PATH environment variable.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Compress-APK   
#>
function Compress-APK {
    $keystoreLocation = (Get-Module -ListAvailable Android-Utils).path
    $keystoreLocation = $keystoreLocation.Replace("Android-Utils.psd1", "my.keystore")
    $keystoreLocationDisplay = $keystoreLocation.split("\")[-1]
    Write-Host "Repacking folder 'out' to 'app-updated.apk' file using keystore '$keystoreLocationDisplay'..." -ForegroundColor Green
    Write-Host "[i] If repack fail then try deleting the folder '$env:LOCALAPPDATA`\apktool\framework' and then perform a new depack/repack cycle." -ForegroundColor Cyan
    Remove-Item app-updated.apk -Recurse -ErrorAction Ignore
    apktool b --use-aapt2 -d out/ -o app-updated.apk
    zipalign -f 4 app-updated.apk app-updated2.apk
    Remove-Item "app-updated.apk"
    Rename-Item -Path "app-updated2.apk" -NewName "app-updated.apk"
    apksigner sign --ks $keystoreLocation --ks-pass pass:mypass app-updated.apk
}

<#
    .DESCRIPTION

    Re-Install patched application (replace app with the same package name) using the current connected ADB instance.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Install-APK     
#>
function Install-APK {
    Write-Host "Replace the current application version with the patched one..." -ForegroundColor Green
    adb install -r -t -d --no-streaming app-updated.apk
}

<#
    .DESCRIPTION

    Check availability of used Android tools.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The access status of all tools.        

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
    Write-Host "ZIPALIGN (https://developer.android.com/studio#downloads):" -ForegroundColor Yellow
    zipalign --version
    Write-Host "APKTOOL (https://bitbucket.org/iBotPeaches/apktool/downloads):" -ForegroundColor Yellow
    apktool --version
    Write-Host "JAVA (https://adoptopenjdk.net):" -ForegroundColor Yellow
    java --version
}

<#
    .DESCRIPTION

    List installed packages on the current connected device using the current connected ADB instance.

    .OUTPUTS

    System. String. All packages present on the device.   

    .EXAMPLE

    PS> Get-Packages    
#>
function Get-Packages {
    Write-Host "List current installed packages..." -ForegroundColor Green
    adb shell pm list packages
}

<#
    .DESCRIPTION

    Get the APK from the provided package name on the current connected device using the current connected ADB instance.

    .PARAMETER appPkg

    Package name of the application.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

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
    Write-Host "Get APK(s) for the path '$appPkg'..." -ForegroundColor Green
    $entries = (adb shell pm path $appPkg).split("\n")
    [System.Collections.ArrayList]$apkFiles = @()
    foreach ($entry in $entries) {
        $pkgPath = $entry.Replace("package:", "").trim()
        $tmp = "";
        foreach ($char in $pkgPath.ToCharArray()) {
            if (-not [Char]::IsControl($char)) {
                $tmp += $char
            }
        } 
        $pkgPath = $tmp
        $tgtFileName = $pkgPath.split("/")[-1]    
        Remove-Item $tgtFileName -Recurse -ErrorAction Ignore
        adb pull "$pkgPath" $tgtFileName
        Write-Host "==> APK stored as '$tgtFileName' file."
        $apkFiles.Add($tgtFileName) | Out-Null
    }
    if ($entries.Count -gt 1) {
        Write-Host "Merge all APK to a single one..." -ForegroundColor Green
        $workDir = "base"
        $baseApkFileName = ""
        Remove-Item $workDir -Recurse -ErrorAction Ignore
        New-Item $workDir -ItemType Directory | Out-Null
        foreach ($apkFile in $apkFiles) {
            if ($apkFile -contains "base.apk") {
                $baseApkFileName = $apkFile
                continue
            }
            apktool d $apkFile -f -o out/
            Copy-Item -Path "out\*" -Destination $workDir -Force -Recurse
        }
        apktool d $baseApkFileName -f -o out/
        Copy-Item -Path "out\*" -Destination $workDir -Force -Recurse
        Remove-Item out -Recurse -ErrorAction Ignore 
        Rename-Item -Path $workDir -NewName "out"
        Compress-APK
        Remove-Item "out" -Recurse -ErrorAction Ignore 
    }
}

<#
    .DESCRIPTION

    Show the device log applying the provided filter on current connected device using the current connected ADB instance.

    .PARAMETER marker

    Filtering expression used as regex.   

    .PARAMETER tag

    Filtering expression used as Android logging TAG.

    .PARAMETER priority

    Filtering log priority ordered from lowest to highest priority (single character in the following range):
    (V)erbose / (D)ebug / (I)nfo / (W)arning / (E)rror / (F)atal / (S)ilent.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The device log according to the filtering criteria provided.        

    .EXAMPLE

    PS> Watch-Log -marker "Wifi"     
	
    .EXAMPLE

    PS> Watch-Log -marker "^(.*(Patched).*)$"  	

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
    Write-Host "Apply filter (https://developer.android.com/studio/command-line/logcat): $filter" -ForegroundColor Green
    $cmd = "adb logcat -v color $filter"
    Invoke-Expression $cmd
}

<#
    .DESCRIPTION

    Show the available functions exposed by the "Android-Utils" module.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. List of available functions.

    .EXAMPLE

    PS> Show-Android-Functions   
    
    .LINK
    
    https://github.com/righettod/powershell-android-utils
#>
function Show-Android-Functions() {
    Get-Command -Module Android-Utils
}

<#
    .DESCRIPTION

    Try to find if the APK use a framwework used to generate native app.

    .PARAMETER apkLocation

    Path to the APK to analyze.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The name of the framework if a one was identified.    

    .EXAMPLE

    PS> Find-Framework -apkLocation app.apk
	
    .LINK
    
    https://medium.com/javarevisited/top-5-frameworks-to-create-cross-platform-android-and-ios-apps-in-2020-d02edf3d01f1
#>
function Find-Framework {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $apkLocation
    ) 
    # Entry format is "FrameworkIdentifier" = "FrameworkFileIdentificationPattern"
    $supportedFrks = @{"XAMARIN" = "out\Xamarin*.dll" ; "CORDOVA" = "out\cordova*.js" ; "REACT-NATIVE" = "out\libreactnative*.so" ; "FLUTTER" = "out\libflutter*.so" ; "UNITY" = "out\libunity*.so" }
    Expand-APK -apkLocation $apkLocation 
    Write-Host "Analyze content of the '$apkLocation' file..." -ForegroundColor Green
    $detectedFrks = ""
    $supportedFrks.GetEnumerator() | ForEach-Object {
        $fileCount = (Get-ChildItem -Recurse $_.Value | Measure-Object).Count
        if ( $fileCount -ne 0 ) {
            $detectedFrks += $_.Key + " "
        }
    }
    if ( $detectedFrks -eq "" ) {
        Write-Host "No framework detected"
    }
    else {
        Write-Host "Detected framework: $detectedFrks"
    }
}

<#
    .DESCRIPTION

    Perform a backup of the provided package name on the current connected device using the current connected ADB instance.

    .PARAMETER appPkg

    Package name of the application.

    .PARAMETER encryptionPassword

    Encryption password specified into the backup interface on the device during the backup process. 
    Do not specify it on the command line but using the prompt, see call example.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Backup-Data-APK -appPkg my.app.package
    
    .LINK
    
    https://github.com/nelenkov/android-backup-extractor
#>
function Backup-Data-APK {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $appPkg,
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]
        $encryptionPassword
    )
    Write-Host "Backup the application data of the package name '$appPkg' to file 'backup.tar'..." -ForegroundColor Green
    $abeLocation = (Get-Module -ListAvailable Android-Utils).path
    $abeLocation = $abeLocation.Replace("Android-Utils.psd1", "abe-all.jar")
    Remove-Item backup.ab -Recurse -ErrorAction Ignore
    Remove-Item backup.tar -Recurse -ErrorAction Ignore
    adb backup -f backup.ab -apk $appPkg
    $encryptionPasswordPlain = (New-Object System.Management.AUtomation.PSCredential("dummy", $encryptionPassword)).GetNetworkCredential().password
    java -jar $abeLocation unpack backup.ab backup.tar $encryptionPasswordPlain
}

<#
    .DESCRIPTION

    Take a screenshot on the current connected device using the current connected ADB instance and download it into the current folder (image is removed after the download).

    .OUTPUTS

    System. String. The output of the tools used.         

    .EXAMPLE

    PS> Get-Screenshot   
#>
function Get-Screenshot {
    Write-Host "Take a screenshot of the current screen and download it into file 'screenshot.png'..." -ForegroundColor Green
    adb shell screencap -p /data/local/tmp/screenshot.png
    adb pull /data/local/tmp/screenshot.png .
    adb shell rm /data/local/tmp/screenshot.png
}

<#
    .DESCRIPTION

    Take a memory dump of the process of the application specified on the current connected device using the current connected ADB instance and download it into the current folder (dump file is removed after the download).

    .PARAMETER appPkg

    Package name of the application.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Get-Memory-Dump -appPkg my.app.package  
	
    .LINK
    
    https://developer.android.com/studio/profile/memory-profiler
#>
function Get-Memory-Dump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $appPkg
    )
    $appPid = adb shell pidof -s $appPkg
    $tmp = "";
    foreach ($char in $appPid.ToCharArray()) {
        if (-not [Char]::IsControl($char)) {
            $tmp += $char
        }
    }
    $appPid = $tmp.trim() -as [int]
    Write-Host "Take a memory dump of the specified application (PID: $appPid) and download it into file '$appPkg.hprof'..." -ForegroundColor Green
    adb shell am dumpheap $appPid /data/local/tmp/$appPkg.hprof
    if ($?) {
        #Dump succeed
        Write-Host "Wait for 15 seconds that data be written to the disk..."  -ForegroundColor Green
        Start-Sleep -Seconds 15
        adb pull /data/local/tmp/$appPkg.hprof .
        adb shell rm /data/local/tmp/$appPkg.hprof
        Write-Host "Create a standard version of the HPROF file from the obtained Android format HPROF file..." -ForegroundColor Green
        $cmd = "hprof-conv $appPkg.hprof $appPkg.standard.hprof"
        Invoke-Expression $cmd
        Get-ChildItem -Path . -Include *.hprof -Name
    }
}

<#
    .DESCRIPTION

    Take a screen recording on the current connected device using the current connected ADB instance and download it into the current folder (video is removed after the download).

    .OUTPUTS

    System. String. The output of the tools used.         

    .EXAMPLE

    PS> Get-Screenrecord
#>
function Get-Screenrecord {
    Write-Host "Take a video and download it into file 'screenrecord.mp4'..." -ForegroundColor Green
    Write-Host "Press CTRL+C to finish the recording." -ForegroundColor Cyan
    # Use a "Try{} Finally{}" to catch the CTRL+C
    # See https://stackoverflow.com/a/15788979/451455
    try {
        adb shell screenrecord /data/local/tmp/screenrecord.mp4
    }
    finally {
        Write-Host "Give 10 seconds to the device to finish writing the file..." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
        adb pull /data/local/tmp/screenrecord.mp4 .
        adb shell rm /data/local/tmp/screenrecord.mp4
    }
}

<#
    .DESCRIPTION

    Cast the current USB connected device screen to the current computer using SCRCPY tool from Genymobile.

    .OUTPUTS

    System. String. The output of the tools used.         

    .EXAMPLE

    PS> Show-Device-Screen
	
    .LINK
    
    https://github.com/Genymobile/scrcpy
#>
function Show-Device-Screen {
    $binaryLocation = (Get-Module -ListAvailable Android-Utils).path
    $binaryLocation = $binaryLocation.Replace("Android-Utils.psd1", "scrcpy\scrcpy.exe")
    & $binaryLocation
}

<#
    .DESCRIPTION

    Get the list of app permissions .

    .PARAMETER appPkg

    Package name of the application.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Get-APK-Permissions -appPkg my.app.package  

    .LINK
    
    https://developer.android.com/studio/command-line/dumpsys   
#>
function Get-APK-Permissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $appPkg
    )
    Write-Host "Get permissions for the package '$appPkg'..." -ForegroundColor Green
    adb shell dumpsys package $appPkg | ForEach-Object {
        if ($_ -like "*permission*") {
            if ($_ -like "*prot=dangerous*") {
                Write-Host $_ -ForegroundColor Red 
            }
            elseif ($_ -like "*granted=true*") {
                Write-Host $_ -ForegroundColor Cyan 
            }
            else {
                Write-Host $_ 
            }
        }
    }
}

<#
    .DESCRIPTION

    Monitor the broadcasts send by the device .

    .PARAMETER marker

    String used to filter the events.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Watch-Broadcasts-Events 

    .EXAMPLE

    PS> Watch-Broadcasts-Events -marker "myapp"

    .LINK
    
    https://developer.android.com/studio/command-line/dumpsys    
#>
function Watch-Device-Broadcasts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]
        $marker
    )
    Write-Host "Monitor broadcasts events..." -ForegroundColor Green
    if ($marker) {
        Write-Host "Filter: $marker"
        while ($true) {
            adb shell dumpsys activity broadcasts | select-string $marker
            Write-Host "Press CTRL+C for exit." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }
    }
    else {
        while ($true) {
            adb shell dumpsys activity broadcasts
            Write-Host "Press CTRL+C for exit." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
        }
    }     
}

<#
    .DESCRIPTION

    Get the list of app flags.

    .PARAMETER appPkg

    Package name of the application.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Get-APK-Flags -appPkg my.app.package  

    .LINK
    
    https://developer.android.com/studio/command-line/dumpsys   
#>
function Get-APK-Flags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $appPkg
    )
    Write-Host "Get flags for the package '$appPkg'..." -ForegroundColor Green
    $flags = [System.Collections.ArrayList]@()
    adb shell dumpsys package $appPkg | ForEach-Object {
        if ($_ -like "*flags=*" -or $_ -like "*pkgFlags=*") {
            $items = $_.split("=")[1].replace("[", "").replace("]", "").trim().split(" ")
            foreach ($item in $items) {
                if (-not $flags.Contains($item)) {
                    $flags.Add($item)
                }
            }
        }
    } | Out-Null
    $flags -join " " 
}

<#
    .DESCRIPTION

    Show the difference between 2 APK files.

    .PARAMETER apkFirstLocation

    Path to the first APK file.

    .PARAMETER apkSecondLocation

    Path to the second APK file.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    System. String. The output of the tools used.        

    .EXAMPLE

    PS> Show-Diff-APK -apkFirstLocation .\app1.apk -apkSecondLocation .\app2.apk
    
    .LINK
    
    https://github.com/JakeWharton/diffuse
#>
function Show-Diff-APK {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $apkFirstLocation,
        [Parameter(Mandatory = $true)]
        [String]
        $apkSecondLocation
    )
    Write-Host "Show the difference between the 2 APK files provided..." -ForegroundColor Green
    $diffuseLocation = (Get-Module -ListAvailable Android-Utils).path
    $diffuseLocation = $diffuseLocation.Replace("Android-Utils.psd1", "diffuse.jar")
    java -jar $diffuseLocation diff $apkFirstLocation $apkSecondLocation
}

<#
    .DESCRIPTION

    Establish the connection between ADB and a Android device on port 5555.

    .PARAMETER deviceHost

    IP address or host name of the device to connect to.

    .INPUTS

    None. You cannot pipe objects to this function.

    .OUTPUTS

    None 

    .EXAMPLE

    PS> Connect-Android-Device -deviceHost 10.10.10.10
	
    .LINK
    
    https://developer.android.com/tools/adb
#>
function Connect-Android-Device {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]
        $deviceHost
    )
    $prt = 5555
    $testConnection = Test-NetConnection -ComputerName $deviceHost -Port $prt -InformationLevel Quiet
    if ($testConnection) {
        Write-Host "Host reachable on port $prt, try to connect ADB..." -ForegroundColor Green
        $target = "$deviceHost" + ":$prt"
        $cmd = "adb connect $target"
        Invoke-Expression $cmd | select-string "Connected"
    }
    else {
        Write-Host "Host not reachable on port $prt!" -ForegroundColor Red
    }
}

# Define exported functions
Export-ModuleMember -Function *
