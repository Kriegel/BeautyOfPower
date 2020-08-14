<#
    Invoking (Parsing) one single script with AST
#>

Import-Module "$PSScriptRoot\..\BeautyOfPower" -Force

 # Get-BopAstType | Select-Object Name,BaseType

$Code = @'
    ${Hallo}
'@

 # get Ast elements
 (Get-BopTokenAndAst -Code $Code).Ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandBaseAst]},$true)