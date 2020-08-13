Function Format-BopAddParameterName {
<#
.SYNOPSIS
    Adds the Parameter Name to Positional Parameter Arguments

.DESCRIPTION
    Adds the Parameter Name to Positional Parameter Arguments

    This Function try to detect Positional Parameter Arguments and
    to add the Parameter name to the Argument, so the Parameter is an Named Parameter Argument.

    This Function Processes only Command Types of
    Alias,Cmdlet,ExternalScript,Filter,Function,Script

    If the Commandtype is other, than the Token is returned untouched and
    a warnig message should be displayed

    The following Commands are Excluded from Processing by default:
    (Hint: Format Alias-CommandNames and Short-CommandNames to OriginNames before using this Function!)

        'Select-Object',
        'Where-Object',
        'ForEach-Object',
        'Write-Output',
        'Write-Host',
        'Write-Information',
        'Write-Verbose',
        'Write-Warning',
        'Write-Error',
        'Write-Debug'

    !!!!!!!!!!! CAUTION !!!!!!!

    A helper Function called 'Get-BopParameterBindingFromInside' will execute
    the Parameter Section of every Command in the source code.
    (see documentation and sourcecode there)

    The Parameter Section of a Command (and therefore the helper Function),
    can have Script Elements that are doing something.
    This can be Script-Code which will do changes or do harm to the System it runs on!
    (in very rare cases)

    Using this Function is on your own accountability !

    Secondly the execution of the Helper Function has a High risk to fail, because
    Parameter Binding may Fail.
    This is handled in this Function.
    All source code Tokens are returned untouched in case of failure.

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

            # List of CommandNames to not add Parameter Names to Positional Arguments
            [String[]]$ExcludeCommand #TODO: Add Support for Alias and Short CommandNames
        )

        Begin {
            $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

            # defining Variables used in Sub-Helper-Functions and in this (parent) Function
            # putting it in AllScope, so that the Helper Functions operate the Variables in this (parent) scope
            New-Variable -Name 'CmdTokensCount' -Value 0 -Option AllScope
            New-Variable -Name 'CmdTokenAfterCount' -Value 0 -Option AllScope
            New-Variable -Name 'CmdProcessing' -Value $false -Option AllScope
            New-Variable -Name 'ArgumentPositionCounter' -Value -1 -Option AllScope
            New-Variable -Name 'DelayedReturnedTokens' -Value ([System.Collections.ArrayList]@()) -Option AllScope

            $NextTokenIsArgumentForNamedParameter = $false

            # create variables to receive tokens and syntax errors:
            $errors = $null
            $CmdTokens = $null

            # Process only Command Types of Alias,Cmdlet,ExternalScript,Filter,Function,Script
            [Int]$AllowedCommandTypes =  [System.Management.Automation.CommandTypes]'Alias' +
                                            [System.Management.Automation.CommandTypes]'Cmdlet' +
                                            [System.Management.Automation.CommandTypes]'ExternalScript' +
                                            [System.Management.Automation.CommandTypes]'Filter' +
                                            [System.Management.Automation.CommandTypes]'Function' +
                                            [System.Management.Automation.CommandTypes]'Script'
            Function Start-BopCmdProcessing {

                Param(
                    [Int]$TokensCount
                )
                # changing Values of Variables in the parent-AllScope
                $CmdTokensCount = $TokensCount
                $CmdTokenAfterCount = 0
                $ArgumentPositionCounter = -1
                $CmdProcessing = $true
                $null = $DelayedReturnedTokens.Clear()
            }
            Function Stop-BopCmdProcessing {
                # changing Values of Variables in the parent-AllScope
                $CmdTokensCount = 0
                $CmdTokenAfterCount = 0
                $ArgumentPositionCounter = -1
                $CmdProcessing = $false
                $null = $DelayedReturnedTokens.Clear()
            }

            If($null -eq $ExcludeCommand) {
                $ExcludeCommand = @(
                    'Select-Object',
                    'Where-Object',
                    'ForEach-Object',
                    'Write-Output',
                    'Write-Host',
                    'Write-Information',
                    'Write-Verbose',
                    'Write-Warning',
                    'Write-Error',
                    'Write-Debug'
                    )
            }

        }

        Process {

            Try {

                If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                    Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
                }

                ForEach ($Tok In $BopToken) {

                    If($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName)) {

                        Write-Verbose "$MyCommandName; Processing CommandName $($Tok.Text)"

                        # getting the equivalent CommandAst from the current CommandName Token
                        $CommandAst = Get-BopAstFromToken -Token $Tok -AstTypeName 'CommandAst' -AstOnly

                        If($null -eq $CommandAst) {
                            Write-Warning "$MyCommandName; CommandAst for Command $($Tok.Text) not found!"
                            Write-Output $Tok
                            Continue
                        }

                        $CommandName = $CommandAst.CommandElements[0].value

                        Write-Host "ExcludeCommand: $($ExcludeCommand -join ', ')" -ForegroundColor 'Cyan'

                        If ($ExcludeCommand -icontains $CommandName) {
                            Write-Verbose "$MyCommandName; Skipping Excluded Command $($Tok.Text)!" -Verbose
                            Write-Output $Tok
                            Continue
                        }

                        # Getting / counting the Tokens in the command line from CommandAst
                        $null = [System.Management.Automation.Language.Parser]::ParseInput(
                                                                            ($CommandAst.Extent.Text),
                                                                            [ref] $CmdTokens,
                                                                            [ref]$errors
                                                                            )

                        # with the Help of the CommandAst we calculate the number of Tokens after a CommandName Token
                        # subtracting the CommandName Token and the EndOfInput Token -2 !
                        # all Processing in this Function makes only sense if the Command has Parameters (and Aguments)
                        # so we start Processing only if the Tokens after a CommandName are more then 0
                        If(($CmdTokens.Count - 2) -gt 0) {

                            $BopCommand = Find-BopCommandName -Name $CommandName

                            If(-Not $BopCommand.EquivalentFound) {
                                Write-Warning "$MyCommandName; Command Name $($Tok.Text) not found in Command Table"
                                 # return the CommandName Token
                                Write-Output $Tok
                                Continue
                            }

                            # Process only Command Types of Alias,Cmdlet,ExternalScript,Filter,Function,Script
                            # using fast binary test for commandtype
                            If([Int]($BopCommand.CommandInfo.CommandType -band $AllowedCommandTypes) -eq 0) {
                                Write-Warning "$MyCommandName; Command Type $($CommandInfo.CommandType.ToString()) for CommandName $CommandName is no Powershell Command"
                                Write-Output $Tok
                                Continue
                            }

                            $BoundParameters = Get-BopParameterBindingFromInside -CommandInfo ($BopCommand.CommandInfo) -CommandAst $CommandAst

                            If($null -eq $BoundParameters) {
                                Write-Warning "$MyCommandName; Can not find BoundParameters for Command Token $($Tok.Text) and CommandAst $($CommandAst.Extent.Text)"
                                 # return the CommandName Token
                                Write-Output $Tok
                                Continue
                            }

                            # Test if there is a bound Parameter which has no equivalent in CommandAst
                            # this indicates an Positional Parameter
                            $PositionalBoundParameters = [System.Collections.ArrayList]@()
                            ForEach($Key in $BoundParameters.Keys) {

                                # skipping special added ParameterSetName value
                                If($Key -ieq 'BeautyOfPowerPSCmdletParameterSetName') {Continue}

                                $KeyNotFound = $true
                                 ForEach($CommandElement in $CommandAst.CommandElements) {
                                    If(-not [String]::IsNullOrEmpty($CommandElement.ParameterName)){
                                        If($Key -ieq $CommandElement.ParameterName){
                                            $KeyNotFound = $false
                                            break
                                        }
                                    }
                                }
                                If($KeyNotFound) {
                                    $null = $PositionalBoundParameters.Add($Key)
                                }
                            }

                            If($PositionalBoundParameters.count -eq 0) {
                                Write-Verbose "$MyCommandName; Can not find Positional Bound Parameters for Command Token $($Tok.Text) and CommandAst $($CommandAst.Extent.Text)"
                                 # return the CommandName Token
                                Write-Output $Tok
                                Continue
                            }

                            Write-Verbose "PositionalBoundParameters $($PositionalBoundParameters -join ', ')"

                            [String]$ParameterSetname = $BoundParameters['BeautyOfPowerPSCmdletParameterSetName']

                            If ([String]::IsNullOrEmpty($ParameterSetname)) {
                                [Array]$PositionalParameters = Get-BopPositionalParameter -CommandInfo ($BopCommand.CommandInfo)
                            }
                            Else {
                                [Array]$PositionalParameters = Get-BopPositionalParameter -CommandInfo ($BopCommand.CommandInfo) -ParameterSetName $ParameterSetname
                            }

                            If($PositionalParameters.Count -eq 0) {
                                Write-Warning "$MyCommandName; Can not find Positional Parameters for Command Token $($Tok.Text) and ParameterSetname '$ParameterSetname'"
                                 # return the CommandName Token
                                Write-Output $Tok
                                Continue
                            }

                            [Array]$ParameterBindingInfos = ForEach($PositionalParameter in $PositionalParameters) {


                                $ParameterBindingInfo = ([PSCustomObject]@{

                                    CommandName = $PositionalParameter.CommandName
                                    ModuleName = $PositionalParameter.ModuleName
                                    ParameterName = $PositionalParameter.ParameterName
                                    ParameterPosition = $PositionalParameter.ParameterPosition
                                    ParameterMetadata = $PositionalParameter.ParameterMetadata
                                    isBound = $false
                                    isBoundPositional = $false
                                    BondResolvedArgumentValue = $null
                                    UnboundArgumentValue = $null
                                   })


                                If($BoundParameters.Keys -icontains $PositionalParameter.ParameterName) {
                                    $ParameterBindingInfo.isBound = $true
                                    $ParameterBindingInfo.BondResolvedArgumentValue = $BoundParameters["$($PositionalParameter.ParameterName)"]
                                }

                                If($PositionalBoundParameters -icontains $PositionalParameter.ParameterName) {
                                    $ParameterBindingInfo.isBoundPositional = $true
                                }

                                # returnig ParameterBindingInfo, to be catched into $ParameterBindingInfos above
                                $ParameterBindingInfo
                            }

                            Start-BopCmdProcessing -TokensCount ($CmdTokens.Count - 2)

                            # return the CommandName Token
                            Write-Output $Tok
                            Continue
                        }
                        Else {
                            Stop-BopCmdProcessing
                            Write-Verbose "$MyCommandName; $($Tok.Text) has no Parameters"
                            # return the CommandName Token
                            Write-Output $Tok
                            Continue
                        }

                    }

                    # if we do not process a Command Line, so we return all Tokens
                    If ((-not $CmdProcessing)) {
                        Write-Verbose "$MyCommandName; Returning Token with Text $($Tok.Text) and Flags $($Tok.TokenFlags) "
                        Write-Output $Tok
                        Continue
                    }

                    # Processing Parameters and Arguments of Cmd line here!
                    # counting the Tokens after a CommandName Token (ParameterName and Argument Tokens)
                    $CmdTokenAfterCount++
                    If($CmdTokenAfterCount -gt $CmdTokensCount) {
                        Stop-BopCmdProcessing
                        Write-Output $Tok
                        Continue
                    }

                    If($Tok.Kind -eq ([System.Management.Automation.Language.TokenKind]::Parameter)) {
                        # Token Text has a dash - in front so we must add it in comparrison !

                        # Test if the Parameter is an Switch-Parameter
                        $isSwitchParameter = $false
                        ForEach ($Param in ($BopCommand.CommandInfo.Parameters.Values)) {
                            If($Param.SwitchParameter -and ("-$($Param.Name)" -ieq $Tok.Text)) {
                                $isSwitchParameter = $true
                                break
                            }
                        }

                        # Remember if the next Token represents the Parameter Argument
                        If(-not $isSwitchParameter) {
                            $NextTokenIsArgumentForNamedParameter = $true
                        }
                        # The current Token is an ParameterName, return it as is
                        Write-Output $Tok
                        Continue
                    }
                    Else {
                        # the current Token must be an Argument

                        # test if the Token is an Argument for a Named Parameter
                        If($NextTokenIsArgumentForNamedParameter) {
                            $NextTokenIsArgumentForNamedParameter = $false

                            # The Token is an Argument for a Named Parameter, return it as is
                            Write-Output $Tok
                            Continue
                        }
                        Else {
                            # BINGO! we found an Positional Argument
                            $ArgumentPositionCounter++
                            Write-Verbose "Found Positional Argument Token '$($Tok.Text)' on Position $ArgumentPositionCounter"
                            ForEach ($ParameterBindingInfo in $ParameterBindingInfos) {
                                If(($ParameterBindingInfo.ParameterPosition -eq $ArgumentPositionCounter) -and $ParameterBindingInfo.isBoundPositional) {
                                    $Tok.Surrogate = "-$($ParameterBindingInfo.ParameterName) $($Tok.Text)"
                                    $ParameterBindingInfo.UnboundArgumentValue = $Tok.Text
                                }
                            }
                        }
                        # last dance, last chance .... Kiss the Frog! ...
                        # returning the result
                        Write-Output $Tok
                    }
                }
            }
            Catch {
                Write-Error -ErrorRecord $_
            }
        }
    }