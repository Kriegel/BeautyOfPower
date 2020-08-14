<#
    Invoking (Parsing) one single script with AST
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
 $ParsePath = "$PSScriptRoot\..\Test\Files-ToParse\Bad-Scripts\PowerShell-Beautifier\Whitespace\WithinLine.ps1"


 # Get-BopAstType | Select-Object Name,BaseType


 # get Ast elements
 (Get-BopTokenAndAst -Path $ParsePath).Ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandBaseAst]},$true)