Function Format-BopExpandParameterShort {
<#
.SYNOPSIS
    Format PowerShell Parameter Token with TokenKind 'Parameter' to expand a shortened (partial) Parameter

.DESCRIPTION
    Format PowerShell Parameter Token with TokenKind 'Parameter' to expand a shortened (partial) Parameter

    Processes only the Token with TokenKind 'Parameter'.

    This Function processes each Parameter in context to his Command
    If the Command is unknown the Parameter Token is returned untouched and
    a warnig message should be displayed

    Processes only Parameters of Command Types of Alias,Cmdlet,ExternalScript,Filter,Function,Script
    If the Commandtype other than the Token is returned untouched and
    a warnig message should be displayed

    calls the internal Function "Format-BopParameter"

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
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            Format-BopParameter -BopToken $BopToken -Format 'ExpandShort'

        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}