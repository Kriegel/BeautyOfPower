Import-Module $PSScriptRoot -Force

# $Code = @'
# {{(({()}))}}
# '@

# Get-BopTokenAndAst -Code $Code -IncludeNestedToken |
# ConvertTo-BopToken |
# Format-BopCasingTypeName #|
#Get-BopAstFromToken -AstTypeName 'WhileStatementAst'


# # #$ParsePath = "$PSScriptRoot\Test\Files-ToParse\EditAndParseMe.ps1" # Parse Edit File
$ParsePath = "$PSScriptRoot\Test\Files-ToParse\Bad-Scripts\Function-Complete-lowercase.ps1"
 #$ParsePath = "$PSScriptRoot\Test\Files-ToParse\Bad-Scripts\Function-Complete-lowercase-LCurlyOnSameLine.ps1"

 # get Ast elements
 #(Get-BopTokenAndAst -Path $ParsePath).Ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandBaseAst]},$true)

$TestFilePath = 'C:\temp\Out-Tesfile.ps1'
$Null = Remove-Item $TestFilePath -confirm:$False -ErrorAction 'ignore'
$Null = New-Item $TestFilePath -ItemType File -Force

Get-BopTokenAndAst -Path $ParsePath -IncludeNestedToken |
ConvertTo-BopToken |
Format-BopCasingTypeName |
Format-BopCasingAttributeName |
Format-BopCasingKeyword |
Format-BopCasingCommandName |
Format-BopCasingParameter |
Format-BopLCurly |
Format-BopCasingTypeMemberName |
ForEach-Object {
    $Token = $_

    # If($Token.Text  -eq 'defaultparametersetname') {
    #     #$Token
    #     $Ast = Get-BopAstFromToken $Token

    # }

    Add-Content -Path $TestFilePath -Value ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline
}

Notepad.exe $TestFilePath