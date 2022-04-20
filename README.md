# Installing Crowdstrike Falcon Protect via Microsoft Intune

Intune doesn't support installing .pkg files directly - instead requiring wrapping them using custom scripts.

It's much easier and more reliable to use a shell script to deploy Crowdstrike Falcon Protect to end-users.

Here's the steps I went through to get it working.

## Step 1 - Deploy configuration profiles

Crowdstrike provides a Configuration profile to enable KExts, System Extensions, Full Disk Access and Web Content Filtering that can be deployed by Intune. Unfortunately this profile does not work on Apple Silicon (M1) devices due to lack of support for KExts.

This would be an easy fix if there was a way to identify arm64 devices in intune for use in Dynamic Groups or the new Filters feature - but so far I haven't figured out a decent way to do this (If you find something, please submit an issue or PR on this repo!).

The closest thing to do to get this to work is to deploy two .mobileconfigs - one with the standalone kexts and one with the rest of the permissions - the kexts will still fail on Apple Silicon, but it doesn't cause any issues with the installation, since Crowdstrike doesn't try to use them on M1.

Deploy the .mobileconfig files in `/MobileConfigs` by doing the following:

1. Open open the [Microsoft Endpoint Manager admin center](https://endpoint.microsoft.com/#home)
2. Select `Devices` -> `Configuration Profiles`
3. Click `Create Profile` \
   ![Step 1 - Create Profile](img/cfg_profile_1.png?raw=true)
4. In the blade that opens on the right, select `macOS` for platform, `Templates` for Profile type, and `Custom` for template name. Click `Create`\
   ![Step 2 - Profile Options](img/cfg_profile_2.png?raw=true)
5. Enter the basic details for the profile. Click `Next`\
   ![Step 3 - Profile Basics](img/cfg_profile_3.png?raw=true)
6. Upload [MobileConfigs/Falcon Profile.mobileconfig](MobileConfigs/Falcon%20Profile.mobileconfig)\
   ![Step 4 - Profile Configuration Settings](img/cfg_profile_4.png?raw=true)
7. Choose the users and/or devices to deploy to\
   ![Step 5 - Profile Assignments](img/cfg_profile_5.png?raw=true)
8. Review the settings for your profile, and click `Create`\
   ![Step 6 - Profile Review](img/cfg_profile_6.png?raw=true)

9. Repeat steps 3-8 for [MobileConfigs/Falcon Profile - kexts.mobileconfig](MobileConfigs/Falcon%20Profile%20-%20kexts.mobileconfig)

## Part 2 - Deployment Script

Now the actual deployment of Crowdstrike - This should work on M1 and Intel with no additional dependencies.

This script uses JXA & Open Scripting Architecture to parse JSON (We used to use Python, but runtimes are being deprecated in MacOS).
(Thanks to both https://www.macblog.org/posts/how-to-parse-json-macos-command-line/ and RhubarbBread on the MacAdmins slack for guidance on this)

How to push the script via Intune:

1. Open open the [Microsoft Endpoint Manager admin center](https://endpoint.microsoft.com/#home)
2. Select `Devices` -> `Scripts`
3. Click `+ Add`\
   ![Step 1 - Create Script](img/script_1.png?raw=true)
4. Enter the basic details for the script\
   ![Step 2 - Basic Script Options](img/script_2.png?raw=true)
5. Upload [CSFalconInstall.sh](CSFalconInstall.sh)

- Select "No" For `Run script as signed-in user` so it runs as the superuser instead of the local user
- Choose your preference for `Hide script notifications on devices`
- Setting `Not Configured` for the Script Frequency will ensure it runs only once (Unless the script is updated or the user's cache is deleted)
- `1 time` for script retries should be plenty, but this setting is at your discretion.\
  ![Step 3 - Script Settings](img/script_3.png?raw=true)

6. Select the users and devices you want to deploy Crowdstrike Falcon Protect to\
   ![Step 4 - Script Assignments](img/script_4.png?raw=true)
7. Review your settings and click `Add` if everything looks correct to you\
   ![Step 5 - Script Review](img/script_5.png?raw=true)
