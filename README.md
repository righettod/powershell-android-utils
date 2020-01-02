# Description

Utility PowerShell module when manipulating APK on Windows.

# Installation

## Step 1

Open a PowerShell window and type this command to install the module into one of the auto-importing location:

```powershell
PS C:\> $moduleLocation = $env:PSModulePath.Split(";")[0] + "\Android-Utils"
PS C:\> git clone https://github.com/righettod/powershell-android-utils.git $moduleLocation
```

## Step 2

Close the PowerShell window above, open a new one and type the following command to test that the module is operational:

```powershell
PS C:\> Get-Command -Module Android-Utils

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Compress-APK                                       0.0        Android-Utils
Function        Expand-APK                                         0.0        Android-Utils
Function        Get-APK                                            0.0        Android-Utils
Function        Get-Packages                                       0.0        Android-Utils
Function        Install-APK                                        0.0        Android-Utils
Function        Test-Tools                                         0.0        Android-Utils
Function        Watch-Log                                          0.0        Android-Utils

PS C:\> Test-Tools
Ensure that the following Android SDK folders are added to the PATH environment variable:
- [SDK_HOME]\platform-tools
- [SDK_HOME]\build-tools\[LAST_INSTALLED_VERSION_FOLDER]
- [SDK_HOME]\tools
- [SDK_HOME]\tools\bin
Current version of Android tools:
ADB (https://developer.android.com/studio#downloads):
Android Debug Bridge version 1.0.41
Version 29.0.5-5949299
APKSIGNER (https://developer.android.com/studio#downloads):
0.8
APKTOOL (https://bitbucket.org/iBotPeaches/apktool/downloads):
2.4.1
```

Module is ready to be used :thumbsup: 

# Help

Use the following command to get help about a function:

```powershell
# Get-Help <FunctionName>
PS C:\> Get-Help Watch-Log
...
```