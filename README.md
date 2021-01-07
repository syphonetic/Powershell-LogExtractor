# Powershell-LogExtractor

This script mainly helps to automate the action of extracting all windows event and registry logs from a local system or a network from the Domain Controller. Exported files have a maxRecords variable to assist with the file sizing and all registry keys have their individual folders for easier navigation. The timeframe of the extracted logs can be modified from within the code (check the comments).

How to run: 

.\logs-extractor.ps1 -> when running on local systems

.\logs-extractor.ps1 [-AD] -> when running on active directories or domain controller

Note: The logs will be extracted to the same directory where you had executed the script. Do ensure that you have ample size in your storage to run your script.

When executing the script:
  1. Make sure you're executing it on administrator mode.
  2. Remember to set your firewall settings to allow the allow Remote Assistance as well as connectivity from the Domain Controller to your systems.
  3. Ensure the following services are active for the remote collection of windows event logs:
     
     a. Remote Procedure Call       
    
     b. DCOM Server Process Launcher
     
     c. WinRM (you can call "winrm quickconfig" in powershell to set up a firewall exception and run the service)

Sample of execution:

[![image.png](https://i.postimg.cc/7LvNQcRt/image.png)](https://postimg.cc/cvmYvD0f)

[![image.png](https://i.postimg.cc/V6k07WzH/image.png)](https://postimg.cc/McgGHRMy)

Sample of end result:

![alt text](https://i.postimg.cc/9Fb52P2B/sample-result.png "Sample of end result")

