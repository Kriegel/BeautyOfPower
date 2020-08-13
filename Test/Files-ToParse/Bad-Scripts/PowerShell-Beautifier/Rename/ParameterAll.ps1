# Parameter Alias
Get-Process | ConvertTo-Csv -NTI

Get-ChildItem $env:windir -ah
Get-ChildItem $env:windir -h

# Parameter shortened
Get-ChildItem -di
Get-Service -Inc 'Lan*'

# Parameter casing
Get-ChildItem -diRecTory
Get-Process -includeusername