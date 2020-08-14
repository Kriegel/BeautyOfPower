<#
    Invoking (Parsing) (short) PowerShell sourcecode
#>

Import-Module "$PSScriptRoot\..\BeautyOfPower" -Force

$Code = @'
-Not
-BNot
-And
'@

# Get-BopTokenAndAst -Code $Code -IncludeNestedToken | # BE CAREFUL WITH NESTED TOKENS !!!!
Get-BopTokenAndAst -Code $Code |
ConvertTo-BopToken |
Format-BopAddParameterName
#Format-BopCasingOperator -MixedCase | Where-Object { $_.Kind -ne 'NewLine'  } | Select-Object Surrogate
#Format-BopCasingScopeModifier -Verbose
# Format-BopAddParameterName #|
# ForEach-Object {
#    Write-Host ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline
# }