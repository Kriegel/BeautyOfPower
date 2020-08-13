Function Format-BopParameter {
<#
.SYNOPSIS
    Format PowerShell Parameter Token with TokenKind 'Parameter' to have an uniform casing or
    to expand Parameter alias or Parameter shortcut

.DESCRIPTION
    Format PowerShell Parameter Token with TokenKind 'Parameter' to have an uniform casing or
    to expand Parameter alias or Parameter shortcut

    Processes only the Token with TokenKind 'Parameter'.

    This Function processes each Parameter in context to his Command
    If the Command is unknown the Parameter Token is returned untouched and
    a warnig message should be displayed

    Processes only Command Types of Alias,Cmdlet,ExternalScript,Filter,Function,Script
    If the Commandtype other than the Token is returned untouched and
    a warnig message should be displayed

    This Function is the "generic basefunction" and is called from the functions:

    - Format-BopCasingParameter
    and
    - Format-BopExpandParameterAlias

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
        [PsObject]$BopToken,

        [Parameter(Mandatory=$true,
            Position=1
        )]
        [ValidateSet('Casing', 'ExpandShort', 'ExpandAlias', 'All')]
        [String[]]$Format
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        $CommandParameterAstList = [System.Collections.ArrayList]@()

        # Process only Command Types of Alias,Cmdlet,ExternalScript,Filter,Function,Script
        [Int]$AllowedCommandTypes =  [System.Management.Automation.CommandTypes]'Alias' +
                                        [System.Management.Automation.CommandTypes]'Cmdlet' +
                                        [System.Management.Automation.CommandTypes]'ExternalScript' +
                                        [System.Management.Automation.CommandTypes]'Filter' +
                                        [System.Management.Automation.CommandTypes]'Function' +
                                        [System.Management.Automation.CommandTypes]'Script'
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Write-Host $BopToken.GetType().FullName -ForegroundColor 'Magenta'
                Write-Host "$BopToken" -ForegroundColor 'Magenta'
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

                # Process only Command Types of Alias,Cmdlet,ExternalScript,Filter,Function,Script
                # using fast binary test for commandtype
                If([Int]($CommandInfo.CommandType -band $AllowedCommandTypes) -eq 0) {
                    Write-Warning "$MyCommandName; Command Type $($CommandInfo.CommandType.ToString()) for CommandName $CommandName is no Powershell Command"
                    Write-Output $Tok
                    Continue
                }

                # Get parameter Informations from CommandInfo
                $Dict = $CommandInfo.Parameters
                $ParamNamesWithDash = ForEach($Key in $Dict.Keys) {"-$($Dict[$Key].Name)"}
                $ParmNotFound = $true
                :BreakDictKeysLoop ForEach($Key in $Dict.Keys) {

                    Switch ($Format) {

                        # Correct Parameter casing
                        {$_ -iContains 'Casing' -or $_ -iContains 'All'} {

                            # The Parameter has a - (dash) in front so we muss add it also!
                            If("-$($Dict[$Key].Name)" -ieq $Tok.Text) {
                                $Tok.Surrogate = "-$($Dict[$Key].Name)"
                                Write-Output $Tok
                                $ParmNotFound = $false
                                break BreakDictKeysLoop # breaking to outer labeled loop
                            }
                        }

                        # Expand shortened Parameter
                        {$_ -iContains 'ExpandShort' -or $_ -iContains 'All'} {

                            # If an ParameterAlias has the same Name like a short Parameter,
                            # in my experience PowerShell resolves shortened Parameter before Alias (see: Get-ChildItem -d)

                            ForEach($ParamNameWithDash in $ParamNamesWithDash) {
                                If($ParamNameWithDash -iLike "$($Tok.Text)*") {
                                    $Tok.Surrogate = $ParamNameWithDash
                                    Write-Output $Tok
                                    $ParmNotFound = $false
                                    break BreakDictKeysLoop # breaking to outer labeled loop
                                }
                            }
                        }

                        # Expand ParameterAlias
                        {$_ -iContains 'ExpandAlias' -or $_ -iContains 'All'} {

                            ForEach ($ParamAlias in $CommandInfo.Parameters[$Key].Aliases) {
                                If("-$ParamAlias" -ieq $Tok.Text) {
                                    $Tok.Surrogate = "-$($Dict[$Key].Name)"
                                    Write-Output $Tok
                                    $ParmNotFound = $false
                                    break BreakDictKeysLoop # breaking to outer labeled loop
                                }
                            }
                        }

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