Function Format-BopCasingCommandName {
 <#
.SYNOPSIS
    Format PowerShell CommandName Token with TokenFlag 'CommandName' to have an uniform casing

.DESCRIPTION
    Format PowerShell CommandName Token with TokenFlag 'CommandName' to have an uniform casing

    Processes only Tokens with the TokenFlag 'CommandName'.

    If Operating system is not Windows, the Token is leaved untouched.
    A warnig message for case missmatch should be displayed on other Operating systems.

    If the Command was found more then once, the Token is leaved untouched.
    A warnig message should be displayed with needful informations

.EXAMPLE

    Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Format-BopCasingCommandName

.EXAMPLE

    Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Format-BopCasingCommandName -Force

.NOTES
    Author: Peter Kriegel
#>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [PsObject]$BopToken,

        # if casing differs on Operating Systems other then Windows,
        # you can force the case correcting with this Parameter on every OS.
        [Switch]$Force
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok in $BopToken) {

                # all tokens which not have the CommandName Flag
                # are returned immediately
                # and loop continues with next Token
                # for simpleness and speed reasond I do not use Select-BopToken here
                If(-Not ($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName))) {
                   Write-Verbose "$MyCommandName; $($Tok.Text) is no CommandName ; Continue"
                   Write-Output $Tok
                   Continue
                }

                $BopCommandName = Find-BopCommandName -Name $Tok.Text

                If($BopCommandName.EquivalentFound) {
                    # command found and exist only on time

                    If($BopCommandName.IsCasingEqual) {
                        # command has already the correct casing
                        # nothing to change; return the Token
                        Write-Output $Tok
                        Continue
                    }
                    Else {
                        # command found but casing differs

                        If(-Not ($env:OS -iLike '*Windows*') -and (-Not ($Force.IsPresent))) {

                            Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Command found but casing differs! '$($Tok.Text)' found: $($BopCommandName.Surrogate)"
                        }
                        Else {
                            # change casing if Windows
                            Write-Verbose "$($PSCmdlet.MyInvocation.MyCommand.Name); Changing Command casing '$($Tok.Text)' to $($BopCommandName.Surrogate)"
                            $Tok.Surrogate = $BopCommandName.Surrogate
                        }

                        Write-Output $Tok
                        Continue
                    }
                }

                If($BopCommandName.MultipleValues.Count -gt 1) {
                    # TODO: Write better handling here
                    ForEach ($Cmd in $BopCommandName.MultipleValues) {
                        Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Command has multiple equivalents! '$($Tok.Text)' has equivalent $($Cmd.Name) with CommandType $($Cmd.CommandType) Source $($Cmd.Source)"
                    }
                    Write-Output $Tok
                }
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}