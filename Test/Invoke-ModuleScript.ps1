<#
    Invoking (Parsing) one single script
#>

Import-Module "$PSScriptRoot\..\BeautyOfPower" -Force

# $ParsePath = "$PSScriptRoot\Test\Files-ToParse\EditAndParseMe.ps1" # Parse Edit File
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\Function-Complete-lowercase.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier\Rename\Alias.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier\Rename\ParameterAlias.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier\Rename\ParameterShort.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier\Rename\ParameterAll.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PsScriptAnalyzer\AvoidPositionalParametersNoViolations.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\Function-Complete-lowercase-LCurlyOnSameLine.ps1"
# $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier\Whitespace\WithinLine.ps1"
 $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Scopes.ps1"


$TestFilePath = 'C:\temp\Out-Tesfile.ps1'
$Null = Remove-Item $TestFilePath -confirm:$False -ErrorAction 'ignore'
$Null = New-Item $TestFilePath -ItemType File -Force

# Get-BopTokenAndAst -Path $ParsePath -IncludeNestedToken | # BE CAREFUL WITH NESTED TOKENS !!!!
Get-BopTokenAndAst -Path $ParsePath |
ConvertTo-BopToken |
# Format-BopCasingTypeName |
# Format-BopCasingAttributeName |
# Format-BopCasingKeyword -ToLower |
# Format-BopCasingCommandName |
# Format-BopCasingParameter |
# Format-BopLCurly -LCurlyOnNewLine|
# Format-BopCasingTypeMemberName |
# Format-BopCasingKnownVariables -MSDefault -IncludeUnknownVars |
# Format-BopExpandCommandAlias -CaseSensitiv -IncludeAll |
# Format-BopParameter -Format 'All' -ErrorAction 'Stop'|
# Format-BopAddParameterName |
Format-BopCasingScopeModifier -LowerCase |
ForEach-Object {
    $Token = $_

    # If($Token.Kind  -eq [System.Management.Automation.Language.TokenKind]::Variable) {
    #     $Token.Text
    #     #$Ast = Get-BopAstFromToken $Token

    # }

    Add-Content -Path $TestFilePath -Value ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline
}

Notepad.exe $TestFilePath