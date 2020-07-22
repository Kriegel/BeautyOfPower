Function Format-BopCasingKeyword {
<#
.SYNOPSIS
    Format PowerShell Keyword Token with TokenFlag 'Keyword' to have an uniform casing

.DESCRIPTION
    Format PowerShell Keyword Token with TokenFlag 'Keyword' to have an uniform casing

    Processes only the Token with TokenFlag 'Keyword'.


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

            ForEach ($Tok In $BopToken) {
                    # Put your Code here !
            }

        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}