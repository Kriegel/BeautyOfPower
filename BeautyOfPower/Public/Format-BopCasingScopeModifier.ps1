Function Format-BopCasingScopeModifier {
<#
.SYNOPSIS
    Format PowerShell Scope Modifiers to have an uniform casing

.DESCRIPTION
    Format PowerShell Scope Modifiers to have an uniform casing

    Simply replace Scope Modifiers in all Tokens.

    The following Scope Modifiers are Replaced:
        '$Global:',
        '$Local:',
        '$Private:',
        '$Script:',
        '$Using:',
        '$Workflow:',
        '$Alias:',
        '$Env:',
        '$Function:',
        '$Variable:',
        '@Global:',
        '@Local:',
        '@Private:',
        '@Script:',
        '@Using:'

        The Dollar $ char or the At @ char is the beginning of replacement and the colon : char is the end.
        (@ is used for so called 'Variable Splatting')

.EXAMPLE


.NOTES
    Author: Peter Kriegel

    TODO: Support for Function Mofifiers and Modifiers without $
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
        [PsObject]$BopToken,

        [Switch]$LowerCase
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        $ScopeModifiers = @('$Global:',
                            '$Local:',
                            '$Private:',
                            '$Script:',
                            '$Using:',
                            '$Workflow:',
                            '$Alias:',
                            '$Env:',
                            '$Function:',
                            '$Variable:',
                            '@Global:',
                            '@Local:',
                            '@Private:',
                            '@Script:',
                            '@Using:'
                        )
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {
                ForEach ($ScopeModifier in $ScopeModifiers) {
                    # TODO: do not replace backticked Scope Modifiers like "`$Script:"
                    If($Tok.Surrogate -imatch [System.Text.RegularExpressions.Regex]::Escape("$ScopeModifier")) {
                        Write-Verbose "$MyCommandName; Processing Scope Modifier '$ScopeModifier' in Token Surrogate $($Tok.Surrogate) TokenKind $($Tok.Kind) and TokenFlags $($Tok.TokenFlags -join ', ')"
                        If($LowerCase.IsPresent) {
                            $Tok.Surrogate = $Tok.Surrogate -ireplace [System.Text.RegularExpressions.Regex]::Escape("$ScopeModifier"), ("$ScopeModifier".Tolower())
                        }
                        Else {
                            $Tok.Surrogate = $Tok.Surrogate -ireplace [System.Text.RegularExpressions.Regex]::Escape("$ScopeModifier"), "$ScopeModifier"
                        }
                    }
                }

                Write-Output $Tok
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}