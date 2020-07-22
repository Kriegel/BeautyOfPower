Function Format-BopCasingTypeMemberName {
<#
.SYNOPSIS
    Format PowerShell MemberName Token with TokenFlag 'MemberName' to have an uniform casing

.DESCRIPTION
    Format PowerShell MemberName Token with TokenFlag 'MemberName' to have an uniform casing

    Processes only the Token with TokenFlag 'MemberName'.

.EXAMPLE

    Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Format-BopCasingTypeMemberName

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

        If($null -eq $Script:BopTypeMemberNamesDictionary) {
            $Script:BopTypeMemberNamesDictionary = Get-BopTypeMemberNames
        }
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {

                If(-Not ($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::MemberName))) {
                    Write-Output $Tok
                    Continue
                }

                # Try to find the MemberName in Dictionary
                $MemberName = $Script:BopTypeMemberNamesDictionary[($Tok.Text.Tolower())]

                If ([String]::IsNullOrEmpty($MemberName)) {
                    Write-Output $Tok
                }
                Else {
                    $Tok.Surrogate = $MemberName
                    Write-Output $Tok
                }


                # Put your Code here !
            }

        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}