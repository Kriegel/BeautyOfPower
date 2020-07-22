Function Format-BopCasingAttributeName {
 <#
.SYNOPSIS
    Format PowerShell Attribute Name Token with TokenFlag 'AttributeName' to have an uniform casing

.DESCRIPTION
    Format PowerShell AttributeName Token with TokenFlag 'AttributeName' to have an uniform casing

    Processes only Tokens with the TokenFlag 'AttributeName'.

    Processes only pure Tokens with the TokenFlag 'AttributeName'.
    AttributeNames can have also the Flag for TypeNames.
    We like to have pure AttributeNames here so Tokens with Flag of TypeNames are not processed
    all tokens which not pure AttributeNames and not have the AttributeName Flag are returned immediately

.EXAMPLE

    Get-BopTokenAndAstAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Format-BopCasingAttributeName

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

                # all tokens which not have the AttributeName Flag
                # are returned immediately
                # and loop continues with next Token
                # for simpleness and speed reasond I do not use Select-BopToken here
                If(-Not (($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::AttributeName)))) {
                    Write-Verbose "$MyCommandName; $($Tok.Text) is no pure Typename ; Continue"
                    Write-Output $Tok
                    Continue
                 }

                # Attribute Names ; AttributeName

                $ReplaceText = $Null

                # try to get the Type out of the Token.Text
                Try {
                    #    |\__/,|   (`\
                    #  _.|o o  |_   ) )
                    #-(((---(((--------
                    # here is the place where the magic happens *meow* *miaow*
                    # the Typename comes as Text
                    # we add squared bracket to the Typenname and create from this String an Scriptblock
                    # if  you invoke the Scriptbock he returns the .NET Type (if it exist in current runspace)
                    # so we can Query the .NET Type Name or Fullname and
                    # map the Type to the Token Text which can be an accelerator or short name
                    $Type = $Null
                    $Type = [Scriptblock]::Create(('[' + $Tok.Text + ']')).Invoke()
                }
                Catch {
                    Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Can not resolve .NET Attribute [$($Tok.Text)Attribute]"
                    Write-Output $Tok
                    Continue
                }

                $ReplaceText = $Null
                If ($Type.Name.EndsWith('Attribute',$True,$Null)) {
                    $ReplaceText = $Type.Name.Substring(0,($Type.Name.Length - 9))
                }

                # TODO: Do we need Namspaces for Attributes here ?

                If($Tok.Text -ieq $ReplaceText) {

                    Write-Verbose "Replacing Attribute $($Tok.Text) with $ReplaceText"
                    $Tok.Surrogate = $ReplaceText

                }
                Else {
                    Write-Warning "No match of $ReplaceText .NET Type with Token Text $($Tok.Text) with "
                }

                Write-Output $Tok
           }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}