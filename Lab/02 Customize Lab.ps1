if (-not (Get-Lab).Name -eq 'KerberosLab') {
    Import-Lab -Name HzdLab -NoValidation
}

$targetVm = 'F2Web1'
$dotnetSdk3Uri = 'https://download.visualstudio.microsoft.com/download/pr/1842d490-55d8-4b96-82a8-468cfd4cd127/6925df11c7c31c7b51018779f76626dc/dotnet-sdk-3.1.416-win-x64.zip'
$dotnetSdk3Installer = Get-LabInternetFile -Uri $dotnetSdk3Uri -Path $labSources\SoftwarePackages -PassThru
Copy-LabFileItem -Path $dotnetSdk3Installer.FullName -ComputerName $targetVm
Invoke-LabCommand -ActivityName 'Expand .net SDK 3' -ScriptBlock {
    Expand-Archive C:\dotnet-sdk-3.1.416-win-x64.zip -DestinationPath 'C:\Program Files\dotnet'
} -ComputerName $targetVm

$dotnetSdk6Uri = 'https://download.visualstudio.microsoft.com/download/pr/343dc654-80b0-4f2d-b172-8536ba8ef63b/93cc3ab526c198e567f75169d9184d57/dotnet-sdk-6.0.101-win-x64.exe'
$dotnetSdk6Installer = Get-LabInternetFile -Uri $dotnetSdk6Uri -Path $labSources\SoftwarePackages -PassThru
Install-LabSoftwarePackage -Path $dotnetSdk6Installer.FullName -CommandLine '/Install /Quiet' -ComputerName $targetVm

$powershell7Uri = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.1/PowerShell-7.2.1-win-x64.msi'
$powershell7Installer = Get-LabInternetFile -Uri $powershell7Uri -Path $labSources\SoftwarePackages -PassThru
Install-LabSoftwarePackage -Path $powershell7Installer.FullName -ComputerName $targetVm

$vsCodeDownloadUrl = 'https://go.microsoft.com/fwlink/?Linkid=852157'
$vscodePowerShellExtensionDownloadUrl = 'https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode/vsextensions/PowerShell/2021.10.2/vspackage'
$vscodeInstaller = Get-LabInternetFile -Uri $vscodeDownloadUrl -Path $labSources\SoftwarePackages -PassThru
Get-LabInternetFile -Uri $vscodePowerShellExtensionDownloadUrl -Path $labSources\SoftwarePackages\VSCodeExtensions\ps.vsix
Install-LabSoftwarePackage -Path $vscodeInstaller.FullName -CommandLine /SILENT -ComputerName $targetVm

Restart-LabVM -ComputerName $targetVm -Wait

Copy-LabFileItem -Path $labSources\SoftwarePackages\VSCodeExtensions -ComputerName $targetVm
Invoke-LabCommand -ActivityName 'Install VSCode Extensions' -ComputerName $targetVm -ScriptBlock {
    dir -Path C:\VSCodeExtensions | ForEach-Object {
        code --install-extension $_.FullName 2>$null #suppressing errors
    }
} -NoDisplay

Invoke-LabCommand -ActivityName 'Install Bruce' -ScriptBlock {
    dotnet tool install bruce -g
} -ComputerName $targetVm

Install-LabWindowsFeature -FeatureName RSAT-AD-Tools -ComputerName $targetVm

Invoke-LabCommand -ActivityName 'Create service user' -ScriptBlock {
    $password = 'Password9' | ConvertTo-SecureString -AsPlainText -Force
    $su = New-ADUser -Name KerbTestService -AccountPassword $password -Enabled $true -PassThru
    $su | Set-ADUser -Add @{
        servicePrincipalName       = 'http/kerbtest.forest2.net', 'http/kerbtest'
        'msds-allowedToDelegateTo' = 'MSSQLSvc/F2SQL1.forest2.net'
    } -Replace @{
        'msds-SupportedEncryptionTypes' = 28
    }
} -ComputerName $targetVm

Invoke-LabCommand -ActivityName 'Set Resource-Based Delegation' -ScriptBlock {
    $c = (Get-ADUser -Identity KerbTestService -Server F2DC1)
    Set-ADComputer -Identity F1SQL1 -PrincipalsAllowedToDelegateToAccount $c

    Get-ADComputer -Identity F1SQL1 -Properties *
} -ComputerName F1DC1 

