# Powershell-LogExtractor

This script mainly helps to automate the action of extracting all windows event and registry logs in a network from the Domain Controller.

When executing the script:
  1. Make sure you're executing it on administrator mode.
  2. Remember to set your firewall settings to allow the allow Remote Assistance as well as connectivity from the Domain Controller to your systems.
  3. Ensure the following services are active for the remote collection of windows event logs:
     a. Remote Procedure Call
     b. DCOM Server Process Launcher
     c. WinRM
