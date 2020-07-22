Function Format-BopCasingKeyword {
 <#
.SYNOPSIS
    Format PowerShell Keyword Token with TokenFlag 'Keyword' to have an uniform casing

.DESCRIPTION
    Format PowerShell Keyword Token with TokenFlag 'Keyword' to have an uniform casing

    Processes only Tokens with the TokenFlag 'Keyword'.
    Keywords having the same Text like their Kind.ToString() so replacement is easy here

.EXAMPLE

    Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Format-BopCasingKeyword

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

            ForEach ($Tok in $BopToken) {

                # all tokens which not have the Keyword Flag
                # are returned immediately
                # and loop continues with next Token
                # for simpleness and speed reasond I do not use Select-BopToken here
                If(-Not ($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword))) {
                   Write-Verbose "$MyCommandName; $($Tok.Text) is no Keyword ; Continue"
                   Write-Output $Tok
                   Continue
                }

               Write-Verbose "$MyCommandName; Keyword found $($Tok.Text)"

               $Tok.Surrogate = $Tok.Kind.ToString()

               Write-Output $Tok
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}