Function Get-BopAstFromToken {
<#
.SYNOPSIS
    Gets the Ast equivalent to an Token

.DESCRIPTION
    Gets the Ast equivalent to an Token

    The Ast can be found because both must have the same StartOffset (from Extent)

.EXAMPLE


.NOTES
    Author: Peter Kriegel

    TODO: Filter even for the Token.Text !?

#>

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        # Must be a BopToken
        $Token,

        [String]$AstTypeName
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name
        $ValidAstTypeNames = Get-BopAstType | Select-Object -ExpandProperty Name | Sort-Object
    }

    Process {

        If((-Not [String]::IsNullOrEmpty($AstTypeName)) -and ($ValidAstTypeNames -inotcontains $AstTypeName)) {
            Write-Error "$MyCommandName; Ast Type Name '$AstTypeName' is not valid`nYou can use this Typenames: '$($ValidAstTypeNames -join "', '")' "
            Return
        }

        Try {

            ForEach($Tok in $Token) {

                If([String]::IsNullOrEmpty($AstTypeName)) {
                    $Predicate = {
                        param( [Ast]$AstObject )
                        return ( ($Tok.StartOffset -eq $AstObject.Extent.StartOffset) )
                    }
                }
                Else {
                    $Predicate = {
                        param( [Ast]$AstObject )
                        return ( ($AstObject.GetType().Name -ieq $AstTypeName) -and ($Tok.StartOffset -eq $AstObject.Extent.StartOffset) )
                    }
                }

                $Tok.RootAst.FindAll($Predicate,$true) | ForEach-Object {

                    $AstToken = $_

                    Write-Output ([PsCustomObject]@{
                        TokenText = $Tok.Text
                        AstText = $AstToken.Extent.Text
                        AstType = ($AstToken.GetType().Name)
                        TokenKind = $Tok.Kind
                        TokenFlags = $Tok.TokenFlags
                        Ast = $AstToken
                    })
                }
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}