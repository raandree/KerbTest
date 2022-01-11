$labName = 'KerberosLab'

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name forest1.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name forest2.net -AdminUser Install -AdminPassword Somepass2
Add-LabDomainDefinition -Name forest3.net -AdminUser Install -AdminPassword Somepass3

Add-LabIsoImageDefinition -Name SQLServer2019 -Path $labSources\ISOs\en_sql_server_2019_standard_x64_dvd_814b57aa.iso

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'= 1GB
}

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password Somepass1

#Now we define the domain controllers of the first forest. This forest has two child domains.
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F1DC1 -DomainName forest1.net -Roles RootDC -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name F1Web1 -DomainName forest1.net -Roles WebServer -Memory 2GB
Add-LabMachineDefinition -Name F1SQL1 -DomainName forest1.net -Roles SQLServer2019 -Memory 2GB

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password Somepass2

#The next forest is hosted on a single domain controller
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F2DC1 -DomainName forest2.net -Roles RootDC -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name F2Web1 -DomainName forest2.net -Roles WebServer -Memory 2GB
Add-LabMachineDefinition -Name F2SQL1 -DomainName forest2.net -Roles SQLServer2019 -Memory 2GB

#--------------------------------------------------------------------------------------------------------------------
Set-LabInstallationCredential -Username Install -Password Somepass3

#like the third forest - also just one domain controller
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name F3DC1 -DomainName forest3.net -Roles RootDC -PostInstallationActivity $postInstallActivity

Add-LabMachineDefinition -Name F3Web1 -DomainName forest3.net -Roles WebServer -Memory 2GB
Add-LabMachineDefinition -Name F3SQL1 -DomainName forest3.net -Roles SQLServer2019 -Memory 2GB

#--------------------------------------------------------------------------------------------------------------------

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winpcap-nmap.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Wireshark.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Add-VMNetworkAdapter -VMName F2Web1 -SwitchName 'Default Switch'

Checkpoint-LabVM -All -SnapshotName 1

Show-LabDeploymentSummary -Detailed
