<#
    Invoking (Parsing) all scripts in specific Folder(s) recursive
#>

Import-Module "$PSScriptRoot\..\BeautyOfPower" -Force


$AllScriptPath = @()
$AllScriptPath += "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier"
$AllScriptPath += "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PsScriptAnalyzer"
$AllScriptPath += "$PSScriptRoot\..\Test\Files-ToParse\Good-Scripts"

Get-ChildItem -Path $AllScriptPath -Filter "*.ps1" -Recurse |
ForEach-Object { $ParsePath = $_.FullName ; Write-Host "Processing File:`n$ParsePath" -ForegroundColor 'Cyan'

# $TestFilePath = 'C:\temp\Out-Tesfile.ps1'
# $Null = Remove-Item $TestFilePath -confirm:$False -ErrorAction 'ignore'
# $Null = New-Item $TestFilePath -ItemType File -Force

# Get-BopTokenAndAst -Path $ParsePath -IncludeNestedToken | # BE CAREFUL WITH NESTED TOKENS !!!!
$null = Get-BopTokenAndAst -Path $ParsePath |
ConvertTo-BopToken |
Format-BopCasingTypeName |
Format-BopCasingAttributeName |
Format-BopCasingKeyword -ToLower |
Format-BopCasingCommandName |
Format-BopCasingParameter |
Format-BopLCurly -LCurlyOnNewLine|
Format-BopCasingTypeMemberName |
Format-BopCasingKnownVariables -MSDefault -IncludeUnknownVars |
Format-BopExpandCommandAlias -CaseSensitiv -IncludeAll |
Format-BopParameter -Format 'All' -ErrorAction 'Stop'|
Format-BopAddParameterName #|
# ForEach-Object {
#     $Token = $_

#     # If($Token.Kind  -eq [System.Management.Automation.Language.TokenKind]::Variable) {
#     #     $Token.Text
#     #     #$Ast = Get-BopAstFromToken $Token

#     # }

#     Add-Content -Path $TestFilePath -Value ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline
# }

# Notepad.exe $TestFilePath

} # EndOf ForEach Get-ChildItem