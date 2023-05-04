![MadeWitVSCode](https://img.shields.io/static/v1?label=Made%20with&message=VisualStudio%20Code&color=blue&?style=for-the-badge&logo=visualstudio) ![AutomatedWith](https://img.shields.io/static/v1?label=Automated%20with&message=GitHub%20Actions&color=blue&?style=for-the-badge&logo=github) ![GenerateDocumentation](https://github.com/righettod/powershell-android-utils/workflows/GenerateDocumentation/badge.svg?branch=master)

# 🤔 Description

📦 PowerShell module providing utility commands to manipulate a APK file on Windows.

💡 This module can be combined with the tool [objection](https://github.com/sensepost/objection) in this way:

1. Use the module to alter the original APK in order to prepare it to be passed to **objection** for patching:

* Example of alteration: Change a value in a Flutter or Cordova configuration file, disable a option in the network security configuration file, disable a flag in the Smali code, etc.

2. Patch the APK with [objection](https://github.com/sensepost/objection/wiki/Patching-Android-Applications).

# 📚 Online documentation

See [here](https://righettod.github.io/powershell-android-utils/).

# 📋 Requirements

> **Note**: You can use the function `Test-Tools` to verify that your installation is OK.

The module assume that the following tools are available in `%PATH%`:

* [adb](https://developer.android.com/studio/command-line/adb)
* [apktool](https://ibotpeaches.github.io/Apktool/)
* [apksigner](https://developer.android.com/studio/command-line/apksigner)
* [zipalign](https://developer.android.com/studio/command-line/zipalign)
* [java](https://adoptopenjdk.net) (Runtime or JDK)

# 🚧 Module installation

## Step 1

Open a PowerShell window and type this command to install the module into one of the auto-importing location:

```powershell
PS> $moduleLocation = $env:PSModulePath.Split(";")[0] + "\Android-Utils"
PS> git clone https://github.com/righettod/powershell-android-utils.git $moduleLocation
```

## Step 2

Close the PowerShell window above, open a new one and type the following command to test that the module is operational:

```powershell
PS> Show-Android-Functions

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Backup-Data-APK                                    1.0        Android-Utils
Function        Compress-APK                                       1.0        Android-Utils
Function        Connect-Android-Device                             1.0        Android-Utils
Function        Expand-APK                                         1.0        Android-Utils
Function        Find-Framework                                     1.0        Android-Utils
Function        Get-APK                                            1.0        Android-Utils
Function        Get-APK-Flags                                      1.0        Android-Utils
Function        Get-APK-Permissions                                1.0        Android-Utils
Function        Get-Memory-Dump                                    1.0        Android-Utils
Function        Get-Packages                                       1.0        Android-Utils
Function        Get-Screenrecord                                   1.0        Android-Utils
Function        Get-Screenshot                                     1.0        Android-Utils
Function        Install-APK                                        1.0        Android-Utils
Function        Show-Android-Functions                             1.0        Android-Utils
Function        Show-Device-Screen                                 1.0        Android-Utils
Function        Show-Diff-APK                                      1.0        Android-Utils
Function        Show-Signature-APK                                 1.0        Android-Utils
Function        Test-Tools                                         1.0        Android-Utils
Function        Watch-Device-Broadcasts                            1.0        Android-Utils
Function        Watch-Log                                          1.0        Android-Utils

PS> Test-Tools
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
JAVA (https://adoptopenjdk.net):
openjdk 12.0.2 2019-07-16
OpenJDK Runtime Environment AdoptOpenJDK (build 12.0.2+10)
OpenJDK 64-Bit Server VM AdoptOpenJDK (build 12.0.2+10, mixed mode, sharing)
```

🚀 Module is ready to be used!

# 👀 Help

Use the following command to get help about a function:

```powershell
# Get-Help <FunctionName> -full
PS> Get-Help Watch-Log -full
```
