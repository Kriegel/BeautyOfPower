$gLobal:Hello = "one"
$lOcal:Hello = "one"
$pRivate:Hello = "one"
$sCript:Hello = "one"
$wOrkflow:Hello = "one"
$aLias:del
$eNv:Computername
$fUnction:mkdir
$Variable:ErrorActionPreference
$gLobal:Hello = @{Inputobject = 'one'} ; Out-String @gLobal:Hello
$lOcal:Hello = @{Inputobject = 'one'} ; Out-String @lOcal:Hello
$pRivate:Hello = @{Inputobject = 'one'} ; Out-String @pRivate:Hello
$sCript:Hello = @{Inputobject = 'one'} ; Out-String @sCript:Hello

### Function Modifier
function global:FuncHello {
  Write-Host "Hello, World"
}

global:FuncHello

### $Using:

$ps = "*PowerShell*"
Invoke-Command -ComputerName S1 -ScriptBlock {
  Get-WinEvent -LogName $uSing:ps
}

$s = New-PSSession -ComputerName S1
$ps = "*PowerShell*"
Invoke-Command -Session $s -ScriptBlock {Get-WinEvent -LogName $uSing:ps}


### @Using:

$Splat = @{ Name = "Win*"; Include = "WinRM" }
Invoke-Command -Session $s -ScriptBlock { Get-Service @uSing:Splat }