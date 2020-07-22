Function Format-BopCasingKeywordSec {
 <#
.SYNOPSIS
    Format PowerShell Keword Token with TokenFlag 'Keyword' to have an uniform casing

.DESCRIPTION
    Format PowerShell Keword Token with TokenFlag 'Keyword' to have an uniform casing

    Takes a Stream of 'System.Management.Automation.Language.Token' and Processes only
    the ones with the TokenFlag 'Keyword'.

    This Function is considered as secure to make Changes to the Sourcecode, because
    the replaced Text is allways of the same length as the original and the
    chars are stay the same except of casing.
    Even case changing is considered secure because Keywords are culture neutral (en-US).

.EXAMPLE

.OUTPUTS

    Stream of System.Management.Automation.Language.Token

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
        [System.Collections.Arraylist]$Token
    )

    Process {
        Try {
            ForEach ($Tok in $Token) {

                # all tokens which not have the Keyword Flag
                # are returned immediately
                # and loop continues with next Token
                # for simpleness and speed reasond I do not use Select-BopToken here
                If(-Not ($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::Keyword))) {
                    Write-Verbose "$($Tok.Text) is no Keyword ; Continue"
                    Write-Output -InputObject $Tok
                    Continue
                }

                Write-Verbose "Keyword found $($Tok.Text)"

                $KewordKindText = $Tok.Kind.ToString()
                # -Cne cannot differentiate between different casing and differen Words
                # so we need 2 If Statments here
                # Test if Text is equal (case insensitiv)
                If ($KewordKindText -ieq $Tok.Text) {
                    If($KewordKindText -Cne $Tok.Text) {
                        Write-Verbose "Append NewText to Keyword $KewordKindText  $($Tok.Text)"
                        # append NewText Property Only if Text casing is different
                        # Write-Output
                        Add-Member -InputObject $Tok -MemberType NoteProperty -Name 'NewText' -Value $KewordKindText -Force -PassThru
                    }
                }
            }
        }
        Catch {
        }
    }
}