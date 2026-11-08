# UOS Windows Application Compatibility Engine|deepin-wine-builder|

## Overview

The UOS Windows Application Compatibility Engine (hereinafter referred to as the "Compatibility Engine") is a tool that uses Deepin Wine to run/package Windows applications. It supports running local .exe files and converting local .exe installers into deb packages.

## Getting Started

When running the Compatibility Engine for the first time (including installing the Compatibility Engine and directly running a Windows installer), please first agree to the "UOS Windows Application Compatibility Engine Software License and Service Agreement."

![Img](./fig/img-20250613150506.png)

### Running the Compatibility Engine

1. Click the launcher icon ![deepin_launcher](../common/deepin-launcher.svg) on the taskbar (on deepin 20, the icon is ![deepin20_launcher](../common/deepin_launcher.svg)) to enter the launcher interface.
2. Scroll up and down with the mouse wheel to browse or search to find the Compatibility Engine icon ![Img](../common/deepin-wine-builder.svg), and left-click to run it.
3. Right-click on ![Img](../common/deepin-wine-builder.svg), you can:
   - Select **Send to Desktop** to create a desktop shortcut for the application.
   - Select **Send to Taskbar** to pin the application to the taskbar for quick launch.
   - Select **Autostart** to add the application to the startup items, so it runs automatically when the computer starts.

![Img](./fig/img-20250613153843.png)

### Closing the Compatibility Engine

- Click ![Img](../common/close.svg) in the Compatibility Engine interface to exit.  
- Click ![Img](../common/icon_menu.svg) at the upper right corner of the interface and select **Exit**.  
- Right-click ![Img](../common/deepin-wine-builder.svg) on the taskbar and select **Close All**.  

## Main Menu

In the main menu ![Img](../common/icon_menu.svg), you can switch window themes, view help manuals, and learn more about the Compatibility Engine.

### Feedback

1. In the Compatibility Engine interface, click ![Img](../common/icon_menu.svg).  
2. Select **Feedback**.  

![Img](./fig/img-20250613154947.png)

To make it easier for everyone to track the progress of their feedback, when you submit feedback, a robot account will automatically post a question thread in the "Wine Zone" section of the deepin community. Users with deepin accounts can also post feedback in the deepin community. R&D and product personnel check and reply to community posts almost daily.

### Theme

Window themes include Light Theme, Dark Theme, and Follow System Theme.  
1. In the Compatibility Engine interface, click ![Img](../common/icon_menu.svg).  
2. Select **Theme** and choose a theme color.  

### Help

View the help manual to further understand and use the Compatibility Engine.  
1. In the Compatibility Engine interface, click !![Img](../common/icon_menu.svg).  
2. Select **Help**.  
3. View the help manual of the Compatibility Engine.  

### Community

1. In the Compatibility Engine interface, click the ![Img](../common/icon_menu.svg).
2. Select **Community**.
3. You can access the community forum to conveniently exchange ideas, share experiences, and report issues with other users.

### About

1. In the Compatibility Engine interface, click ![Img](../common/icon_menu.svg).  
2. Select **About**.  
3. View the version and introduction of the Compatibility Engine.  

### Exit

1. In the Compatibility Engine interface, click ![Img](../common/icon_menu.svg).  
2. Select **Exit**.  

## Operation Guide  

### Account Login

The Compatibility Engine supports one-click login with deepin ID:
- If the system is already logged in with a deepin ID account, opening the Compatibility Engine will automatically log you in.
- When the system is logged out of the deepin ID account, the Compatibility Engine will also be logged out.
- When the system is not logged into the deepin ID account, opening the Compatibility Engine and clicking the “Log In” button will launch the system account login module. After logging in via QR code or other methods, both the Compatibility Engine and the system will be logged in.
- When you log out of your account within the Compatibility Engine, the system account will also be logged out.

![Img](./fig/img-login-deepin.png)

Main Features of the My Account Center:
- My Submissions: Apps submitted under this account
- My Wishs: Wishlists submitted under this account
- My Feedback: Issue reports submitted under this account
- Log Out: Log out of this account

![Img](./fig/img-20260824182233.png)

### Running Applications

#### Double-click to Run

If the Compatibility Engine is already installed on the system, you can directly double-click the local exe to run the application. After double-clicking, the program will automatically start wine.  

![Img](./fig/img-20250613155512.png)

If the run is successful, the application will open directly.
If the run fails, you can debug it using "Repair" or "Debug" (see the "Application Debugging" section below) to improve the success rate.

![Img](./fig/img-20250613165908.png)

Clicking "Debug" will take you to the advanced debugging interface, which requires manual debugging and is suitable for experienced enthusiasts and developers.

 Clicking "Repair" will automatically fix issues during runtime (only supported in certain scenarios, such as missing .NET environments).

Clicking "Common Issues" will open the help manual's FAQ section, providing suggestions for debugging. 

![Img](./fig/img-20260318155006.png)

Clicking "Feedback" allows you to report issues to the community. The more detailed the problem description, the easier it is to locate the issue.

Clicking "View Logs" will highlight common errors in red, as shown below: 

![Img](./fig/img-20250613170536.png)

#### Debug Installation

Since version V3.2, the Compatibility Engine supports debug installation/running. When installing an application via debug mode, even if the installation fails, a shortcut (application container) will be generated in the "My Applications" list for subsequent debugging. The specific operation is as follows:
Right-click the .exe file you want to debug install/run and select "Compatibility Engine Debugging" as shown below:

![Img](./fig/img-20250613170707.png)

#### Adding Applications

On the Compatibility Engine home page, select **Add App** to open a local file dialog and choose the .exe program you want to install or run. 

![Img](./fig/img-20250613172213.png)

If you don't know how to use the Compatibility Engine to install and debug applications, you can click the "Quick Start" to view the user help manual.

#### Drag-and-Drop Installation

On the "My Applications" page, you can directly drag and drop .exe files into the page to install them. The installation effect is the same as double-clicking the .exe.

#### Specified Installation

Install applications using a specified configuration file. Starting from version V3.3.0, the Compatibility Engine has added an "All Applications" module, which provides a large number of Wine-tested application configuration files. Open the application installation panel, select the corresponding version of the .exe file, and use the tested configuration files to install Wine applications.

![Img](./fig/img-20250613172744.png)

Click "Install" to open the panel for selecting an installer. This installation method requires you to provide the Windows installer. The installation panel provides detailed information about the Windows installer: software name, software version, and software official website. Downloading the corresponding installer version based on the software information provided on the panel will yield a better Wine experience.

If the system environment meets the software installation requirements, you will see the following information:

![Img](./fig/img-20260318160931.png)

If the system environment lacks dependencies and cannot meet the software installation requirements, click the blue text link on the install panel to download and install the missing dependencies. After installing the dependencies, select the .exe file and click "Next" to continue the installation.

### Community

Starting from version V3.4.0, the Compatibility Engine has added a "Community Co-construction" module. This module currently mainly displays information about community application submissions and application adaptation requests.

#### App Delivery

This section primarily showcases information about applications successfully run on Wine, submitted by community contributors.

![Img](./fig/deepin-wine-builder_AppDelivery.png)

Click “I want to Submit” to go to the “My Applications” module and submit successfully installed Wine applications. This feature submits the configuration environment information for running Wine applications. The “All Applications” section lists the application runtime environment configuration information.

#### Wish Wall

This section primarily showcases software that users hope to see supported by Wine.

![Img](./fig/deepin-wine-builder_wish.png)

Click “Make a Wish” to open the Wish Form submission panel. You can directly drag and drop EXE files into the submission panel. The compatible engine will automatically read the EXE file's information to populate the fields, including the application name, version number, and EXE file size.

![Img](./fig/deepin-wine-builder_WishForm.png)

### Application Management

The **My Applications** section on the homepage of the Compatibility Engine displays exe applications you have installed and run in chronological order. You can perform the following operations on these applications: run, edit shortcuts, advanced debugging, run in terminal, open application directory, package application, Delivery App, create desktop icons, uninstall, etc.  

![Img](./fig/img-20250613175104.png)

#### Edit Details

Edit the shortcut generated in **My Applications** after application installation, mainly to modify the shortcut name and logo:  

![Img](./fig/img-20250613175346.png)

#### Advanced Debugging

Debug issues such as DPI resolution anomalies, 3D rendering, DLL missing, and font missing after software installation.  

![Img](./fig/img-20250613175523.png)

#### Create Desktop Icon

If the application does not generate a desktop shortcut after installation, or the generated shortcut is deleted, you can use the **Create Desktop Icon** function to generate a desktop shortcut.  

### Application Debugging  

#### How to Enter Advanced Debugging

You can debug an application if the installation fails or if problems occur after installation and launch.
If the application installation fails and debugging is needed, you can directly click "I want to debug" on the window to enter the advanced debugging interface, as shown below:

![Img](./fig/img-20250613165908.png)

If problems like black screen or font abnormalities occur after application installation and launch, and debugging is needed, find the application in "My Applications" on the Compatibility Engine home page, click the menu, and select "Advanced Debugging," as shown below:

![Img](./fig/img-20250613175717.png)

#### Main Functions of Advanced Debugging

![Img](./fig/img-20260429175330.png)

Click “Debugging Runs” to run the application in debug mode. You can view the application's runtime logs on the right. Before clicking “Debugging Runs” you can select a debug mode:

- Basic Diagnosis: Analyzes dependency and environment issues and provides repair recommendations;
- In-depth Diagnosis: Thoroughly investigates the root causes of anomalies in the runtime logs and provides solutions;
- Startup Diagnosis: Analyzes application startup time and identifies performance bottlenecks;
 
**Basic Configuration**  
Mainly includes 3D rendering settings, DPI settings, dxvk and vkd3d driver settings, Windows version, and wine container version.  

![Img](./fig/img-20250613175523.png)

**Wine Parameter**  
Set startup parameters, log channels, environment variables, and log file storage path/name.  

![Img](./fig/img-20250613175915.png)

**DLL Override**  

![Img](./fig/img-20250613175955.png)

**Font Replacement**  

![Img](./fig/img-20250613180105.png)

**Component Installation**  

![Img](./fig/img-20250613180149.png)

Supports exporting components of installed applications to local storage, and also supports importing components required for offline application installation and operation.

![Img](./fig/img_20250910141646.png)

**Debugging Tools**  

![Img](./fig/img-20250613180217.png)

**Common Functions and Debug Logs**  
The advanced debugging tools provide **Common Functions** and **Debug Logs** modules for faster and more intuitive application debugging.  

![Img](./fig/img-20250613180505.png)

Click the ![Img](../common/img-20250310153522.png) button at the upper right corner of the advanced debugging page to collapse the **Common Functions** and **Debug Logs** modules.  

![Img](./fig/img-20250613181219.png)

### Application Packaging

Find the application to be packaged into a deb package in **My Applications** on the homepage of the Compatibility Engine, click the menu, select **Package Application**.

![Img](./fig/img-20250613183624.png)

Enter basic application information, and click **OK** to start the packaging process. 

![Img](./fig/img-20250613183818.png)

### Delivery App

Locate the application you wish to submit within the “My Applications” section on the Compatibility Engine homepage. Click the menu, select “Delivery App” then enter the application's basic information. Finally, click “Submit” to complete the submission.

![Img](./fig/deepin-wine-builder_20251121134735.png)

> ![notes](../common/notes.svg)：It should be noted that to avoid duplicate submissions, applications installed via the "All Applications" route using officially provided specific versions cannot be submitted.

## Common Issues  

### Notes on Green Software

#### How to Run Green Software

Green software runs directly without installation. After running, a shortcut will be generated in **My Applications** on the homepage of the Compatibility Engine for direct use afterward.  
If a running green application does not exit completely, check if it is minimized in the system tray at the lower right corner.  
For applications that cannot exit, open Task Manager, search for the exe name to find the corresponding process, select it, and click **Force Exit** in the right-click menu:  

![Img](./fig/img-20250613184058.png)

#### How to Package Green Software

If the application to be packaged is green software, the following prompt will pop up:  

![Img](./fig/img-20250613184156.png)

The choice between **Package Application Itself** and **Package Folder** depends on the application itself.  
If the green software is very simple and can run without any fig in the same directory, such as:  

![Img](./fig/img-20250613184611.png)

You can directly select **Package Application Itself** when packaging, and the deb package will only contain this exe file.  
However, in most cases, green software comes with running DLLs, resource fig, and various configuration fig besides the exe, such as:  

![Img](./fig/img-20250613184445.png)

In this case, select **Package Folder** and choose the path of the unzipped green software. The compatibility engine defaults to opening the exe's directory. If the exe is in a deep directory, you need to select a higher-level folder to ensure the green software is fully packaged.  

### How to Run .Net Applications

For applications requiring the .Net Framework for installation, some will remind users to install it, and the compatibility engine will also detect if the running exe is a .Net application:  

![Img](./fig/img-20250613155646.png)

If detected, a repair prompt will appear when installation fails:  

![Img](./fig/img-20250613170909.png)

Click **Repair** to install the recommended .Net version.  

![Img](./fig/img-20250613171703.png)

You can also install Mono, an open-source implementation of .Net Framework, in **Advanced Debugging > Component Installation**:  

![Img](./fig/img-20250613171857.png)

### Application Runs Successfully on First Installation but Fails After Exit

For versions after V3.2 of the compatibility engine, if this issue occurs, enter the application's advanced debugging page and directly click **Debug Run**, as mentioned earlier:  

![Img](./fig/img-20250613185326.png)

The application run log will be displayed, where errors like the following can be seen:  
>0114:err:module:import_dll Library MSVBVM60.DLL (which is needed by L"C:\\Program fig (x86)\\Kingsoft\\TypeEasy\\TypeGame\\Mole\\TypeGame.exe") not found  
0114:err:module:loader_init Importing dlls for L"C:\\Program fig (x86)\\Kingsoft\\TypeEasy\\TypeGame\\Mole\\TypeGame.exe" failed, status c0000135  

It is clear from the log that the application is missing DLLs not implemented in the current wine version. The Compatibility Engine V3.2 provides repair suggestions for error logs in the debug log window. Click the text link to jump to the component installation module and install the corresponding DLL:  

![Img](./fig/img-20250613185501.png)

The application may be missing multiple DLLs. After supplementing one DLL and clicking debug run again, the same error will reappear with a different DLL name. Some small applications can run successfully after supplementing DLLs in **Component Installation**.  

![Img](./fig/img-20250613185650.png)

If the missing DLL cannot be installed from the component list, download the DLL from the internet, open the container C drive in the **Debugging Tools** of the advanced debugging interface, and manually copy the DLL to windows/system32 (or windows/syswow64).  

### Application Window Black Screen

Wine provides three rendering modes:  
- gdi: Disables 3D acceleration.  
- opengl: By default, wine uses OpenGL to implement Direct3D rendering API.  
- Vulkan: Uses Vulkan to implement Direct3D rendering API, but the implementation is incomplete.  

![Img](./fig/img-20250613185908.png)

When encountering a black screen after application installation, try setting the rendering mode to gdi.  

![Img](./fig/img-20250613185954.jpg)

### Small Text on High-DPI Screens

If the displayed font is too small on a high-DPI screen, increase the DPI value:  

![Img](./fig/img-20250613190047.png)

### Game Application Settings

#### How to Install and Use Proton

**Proton** is a compatibility layer developed and maintained by Valve (the developer of Steam). It includes a highly customized and optimized Wine version, as well as a series of patches and integrations for gaming experience optimization, enabling Windows-based games and applications to run seamlessly on Linux operating systems.  

The Compatibility Engine currently adapts two different Proton versions:  
- deepin-proton: A stable Proton version packaged based on the upstream branch. The compatibility engine adds wow64 support on top of it. Advantages: Can run on pure 64-bit systems, support most 32-bit games, and does not require installing 32-bit graphics drivers. Disadvantages: wow64 introduces performance overhead when running 32-bit games, and some 32-bit games cannot be run due to wow64's own limitations.  
- ge-proton: Can be understood as a technical preview of the official Proton. It is a Proton branch version created and maintained by community developer GloriousEggroll, based on official Proton code but incorporating more experimental, cutting-edge, or merged patches. Since it is packaged based on binary fig, installing 32-bit graphics drivers is required to run some 32-bit games.  

**How to Install Proton**:  
After adding the game to the compatibility engine, enter the game application's advanced debugging page, as shown below:  

![Img](./fig/img-20250613175717.png)

In the opened debugging interface, click **Install proton**, select the Proton version to install, and click install to jump to the App Store page for installation:  

![Img](./fig/img-20250613174015.png)

After completing the installation in the App Store, return to the compatibility engine, select **deepin-proton9** or **ge-proton9** from the Wine version drop-down menu in the advanced debugging page, and then rerun the application.  

![Img](./fig/img-20250613174142.png)

#### How to Install Vulkan Drivers

dxvk is a Vulkan implementation of DirectX 11, and vkd3d is a Vulkan implementation of DirectX 12. After installing Vulkan drivers, you can run games by configuring these two options.  

![Img](./fig/img-20250613174309.png)

For AMD users, install mesa-vulkan-drivers:  
Open the terminal and enter the command: `sudo apt install mesa-vulkan-drivers`  

For NVIDIA users, install nvidia-vulkan-icd:  
Open the terminal and enter the command: `sudo apt install nvidia-vulkan-icd`  

Then install vulkan-tools and vkcube:  
Open the terminal and enter the command: `sudo apt install vulkan-tools`  

Finally, Open the terminal and run the command:`vkcube`. If the vkcube demo pops up, the Vulkan graphics driver is successfully set up:  

![Img](./fig/img-20250613174948.png)

For graphics driver installation and version selection, refer to: [How to Install Graphics Drivers for deepin 23](https://www.deepin.org/zh/deepin-23-install-driver-gpu/)  

#### Important Notes

- To run large games, after installing Vulkan drivers, configure dxvk and vkd3d in the **Advanced Debugging** interface to enhance the gaming experience.  
- deepin 25 and later systems are gradually phasing out support for 32-bit. If you need to run 32-bit legacy games on deepin 25, prioritize using deepin-proton9.  
- On deepin 20 and UOS UOS v20 systems, due to outdated graphics drivers in the system repository, the running quality of games/applications cannot be guaranteed, and the latest dxvk and vkd3d versions cannot be used for gaming rendering acceleration. Consider switching dxvk to a version below 1.10, and if the graphics card supports vkd3d, switch it to a version below 2.10.  

### System Environment Repair

When the Compatibility Engine fails to work properly, it may be due to system environment issues. Common situations include:

- Base container corruption: The ostree container files required for Wine runtime are incomplete or damaged
- Insufficient disk space: Not enough space on the system disk to create or run application containers

For such issues, try deleting the corrupted container data and restarting. Open terminal and paste the following command, then press Enter:

```
rm -rf ~/.local/share/deepin-wine-bottles/bottles/ostree_bottle/
```

How to open the terminal:
Right-click on a blank area of the system desktop and select **"Open in Terminal"**.

After deletion, run `deepin-wine-builder` in the terminal to launch the Compatibility Engine, then try running the application again. If the problem persists, please post feedback in the community with the terminal output of `deepin-wine-builder`.

### Other Issues

For more issues encountered when using the Compatibility Engine, refer to: [How to Seamlessly Run Windows Applications on Linux Systems](https://bbs.deepin.org/post/283011)