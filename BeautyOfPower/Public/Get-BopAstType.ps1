Function Get-BopAstType {
<#
.SYNOPSIS
    Get all AST Types or TypeNames avaiable in current .NET version

.DESCRIPTION
    Get all AST Types or TypeNames avaiable in current .NET version

.EXAMPLE

    Get-BopAstType

    Get all AST Types or TypeNames avaiable in current .NET version

.EXAMPLE

    Get-BopAstType

    Get all AST Types or TypeNames avaiable in current .NET version

.EXAMPLE

    Get-BopAstType -Name '*Expression*'

    Get all AST Types with Name *Expression*

.EXAMPLE

    Get-BopAstType -Name 'ExpressionAst','TernaryExpressionAst','BinaryExpressionAst'

    Get AST Types with Name 'ExpressionAst','TernaryExpressionAst','BinaryExpressionAst'

.NOTES
    Author: Peter Kriegel
#>

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        # Name of the Ast class, supports wildcards
        [String[]]$Name = '*'
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        $AstTypes = [System.Management.Automation.Language.Ast].Assembly.GetTypes() | Where-Object {$_.IsSubclassOf([System.Management.Automation.Language.Ast])}

    }

    Process {

        Try {

            ForEach ($TypeName In $Name) {
                $AstTypes | Where-Object {$_.Name -like $TypeName}
            }

        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}