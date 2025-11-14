# Windows Build Fix - ATL Libraries Required

## Problem
The build is failing because `flutter_secure_storage_windows` requires ATL (Active Template Library) which is not installed in Visual Studio.

## Solution

You need to install ATL components in Visual Studio:

### Steps:
1. Open **Visual Studio Installer**
2. Click **Modify** on your installed Visual Studio version
3. Go to the **Individual Components** tab
4. Search for "ATL" in the search box
5. Check the following components:
   - **C++ ATL for latest v143 build tools (x86 & x64)**
   - **C++ ATL for latest v143 build tools with Spectre Mitigations (x86 & x64)**
6. Click **Modify** to install

### Alternative: Install via Command Line
If you have Visual Studio Build Tools, you can also install via command line:
```powershell
& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" modify --installPath "C:\Program Files\Microsoft Visual Studio\2022\Community" --add Microsoft.VisualStudio.Component.VC.ATL --quiet
```

Replace the install path with your actual Visual Studio installation path.

## After Installation
1. Close any running Visual Studio instances
2. Run `flutter clean`
3. Run `flutter build windows` or `flutter run -d windows`

## Note
The CMakeLists.txt files have been updated to support ATL, but you still need to install the ATL components in Visual Studio for the build to succeed.

