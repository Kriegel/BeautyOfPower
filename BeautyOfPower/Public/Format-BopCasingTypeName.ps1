Function Format-BopCasingTypeName {
 <#
.SYNOPSIS
    Format PowerShell TypeName Token with TokenFlag 'TypeName' to have an uniform casing

.DESCRIPTION
    Format PowerShell TypeName Token with TokenFlag 'TypeName' to have an uniform casing

    Processes only pure Tokens with the TokenFlag 'TypeName'.
    Typenames can have also the Flag for AttributeName.
    We like to have pure Typenames here so Tokens with Flag of AttributeName are not processed
    all tokens which not pure Typenames and not have the Typename Flag are returned immediately

.EXAMPLE

    Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Format-BopCasingTypeName

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

        # TextInfo.ToTitleCase() Method is to Capitalize the first letter of each word
        # TextInfo can be found in the CultureInfo Object
        $TextInfo = ([System.Globalization.CultureInfo]::InvariantCulture).TextInfo

        # Creating a Hashtable to map .Net Type Names to TypeAccelerators Names
        # Key is the normal .Net Typename the Value is the Accelerator Short name
        $PsAccelerators = @{}
        ForEach ($Name in ([psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get).Keys) {
            $PsAccelerators[([String]([Scriptblock]::Create("[$Name].Name")).Invoke())]= $TextInfo.ToTitleCase($Name)
        }
        # Add Missing Add TypeAccelerators Names to Hashtable
        $PsAccelerators['Single'] = 'Float'
        $PsAccelerators['Int32'] = 'Int'
        $PsAccelerators['Int64'] = 'Long'

    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok in $BopToken) {

                # Typenames can have also the Flag for AttributeName
                # we like to have pure Typenames here so Tokens with Flag for AttributeName are not processed
                # all tokens which not pure Typenames and not have the Typename Flag are returned immediately
                # the and loop continues with next Token
                # for simpleness and speed reasond I do not use Select-BopToken here
                If(-Not (($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::TypeName) -and (-Not $Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::AttributeName))))) {
                   Write-Verbose "$MyCommandName; $($Tok.Text) is no pure Typename ; Continue"
                   Write-Output $Tok
                   Continue
                }

                Write-Verbose "$MyCommandName; TypeName found $($Tok.Text)"

                # TypeNames

                $ReplaceText = $Null

                # try to get the Type out of the Token.Text
                Try {
                    $Type = $Null
                    #    |\__/,|   (`\
                    #  _.|o o  |_   ) )
                    #-(((---(((--------
                    # here is the place where the magic happens *meow* *miaow*
                    # the Typename comes as Text
                    # we add squared bracket the the Typenname and create from this String an Scriptblock
                    # if  you invoke the Scriptbock he returns the .NET Type (if it exist in current runspace)
                    # so we can Query the .NET Type Name or Fullname and
                    # map the Type to the Token Text which can be an accelerator or short name
                    $Type = [Scriptblock]::Create(('[' + $Tok.Text + ']')).Invoke()
                }
                Catch {
                    Write-Verbose "$MyCommandName; Can not resolve .NET Type [$($Tok.Text)]"
                    Write-Output $Tok
                    Continue
                }

                If($Null -ne $Type ) {

                    $ShortName = $Null
                    $ShortName = $PsAccelerators[($Type.Name)]

                    # because PowerShell allows to drop the first Namespace element
                    # we create an Name without the first Namespace element
                    # eg. System.Text.StringBuilder is resolved to Text.StringBuilder
                    $Array = $Type.FullName.Split('.')
                    $DroppedNamespaceName = $Array[1..($Array.count -1)] -join '.'

                    $Replace = $True

                    Switch ($Tok.Text) {

                        {$_ -ieq $DroppedNamespaceName} { $ReplaceText = $DroppedNamespaceName }

                        {$_ -ieq $Type.Name} { $ReplaceText = $Type.Name }

                        {$_ -ieq  $Type.FullName} { $ReplaceText = $Type.FullName }

                        {$_ -ieq $ShortName} {$ReplaceText = $ShortName}

                        Default {
                            $ReplaceText = $Null
                            Write-Warning "$MyCommandName; No match of .NET Type [$($Tok.Text)]"
                            $Replace = $False
                        }
                    }

                    If($Replace) {
                        Write-Verbose "$MyCommandName; Replacing [$($Tok.Text)] with [$ReplaceText]"
                        $Tok.Surrogate = $ReplaceText
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