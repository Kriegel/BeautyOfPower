Function Format-BopCasingParameter {
<#
.SYNOPSIS
    Format PowerShell Parameter Token with TokenKind 'Parameter' to have an uniform casing

.DESCRIPTION
    Format PowerShell Parameter Token with TokenKind 'Parameter' to have an uniform casing

    Processes only the Token with TokenKind 'Parameter'.

    This Function processes each Parameter in context to his Command
    If the Command is unknownen the Parameter Token is returned untouched and
    a warnig message should be displayed

.EXAMPLE


.NOTES
    Author: Peter Kriegel
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
        [PsObject]$BopToken
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name
        $CommandParameterAstList = [System.Collections.ArrayList]@()
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {

                If($Tok.Kind -ne ([System.Management.Automation.Language.TokenKind]::Parameter)) {
                    Write-Output $Tok
                    Continue
                }

                # A parameter must processed in context to the Command the parameter belongs to
                # the Ast has this context Information for us
                # so we go and get the Command Ast from the Token

                # run Ast search only once per Pipeline
                If ($CommandParameterAstList.Count -eq 0 ) {
                    # find all CommandParameterAst in root Script Ast
                    $CommandParameterAstList = $Tok.RootAst.FindAll({param([Ast] $AstObject) $AstObject -is [CommandParameterAst] }, $true)
                }

                # search Ast equivalent to the Token
                # this can be found because both must have the same StartOffset
                $CommandName = $Null
                ForEach ($ParamAst in $CommandParameterAstList) {
                    If($Tok.StartOffset -eq $ParamAst.Extent.StartOffset) {
                        # The Parent of the CommandParameterAst holds the Command Name
                        $CommandName = $ParamAst.Parent.CommandElements[0].value
                        break
                    }
                }

                If($null -eq $CommandName) {
                    Write-Warning "$MyCommandName; Command Name for Parameter $($Tok.Text) not found in Ast !"
                    Write-Output $Tok
                    Continue
                }

                $BopCommandName = Find-BopCommandName -Name $CommandName

                If(-Not $BopCommandName.EquivalentFound) {
                    Write-Warning "$MyCommandName; Command Name $CommandName for Parameter $($Tok.Text) not found in Command Table"
                    Write-Output $Tok
                    Continue
                }

                $CommandInfo = $null
                $CommandInfo = $BopCommandHashList[($BopCommandName.Surrogate)][0]

                If($null -eq $CommandInfo) {
                    Write-Warning "$MyCommandName; CommandInfo for CommandName $CommandName not found in Command Table"
                    Write-Output $Tok
                    Continue
                }

                # Get parameter Informations from CommandInfo
                $Dict = $CommandInfo.Parameters
                $ParmNotFound = $true
                ForEach($Key in $Dict.Keys) {
                    # The Parameter has a - in front so we muss add it also!
                    If("-$($Dict[$Key].Name)" -ieq $Tok.Text) {
                        $Tok.Surrogate = "-$($Dict[$Key].Name)"
                        Write-Output $Tok
                        $ParmNotFound = $false
                        break
                    }
                }

                # all processing was without success .... *cry*
                # return unchanged Token
                If($ParmNotFound) {
                   Write-Output $Tok
                }

            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}