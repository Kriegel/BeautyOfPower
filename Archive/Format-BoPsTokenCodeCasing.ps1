Function Format-BoPsTokenCodeCasing {
<#
.Synopsis

   Takes PowerShell code and corrects the casing of Commands and Powershell Keywords

.DESCRIPTION

   Takes PowerShell code and corrects the casing of Commands and Powershell Keywords

   Commands Types are:
    Cmdlelt
    Function
    Application
    
    and other That Get-Command knows

    Alias ist NOT processed here! Because this should be Expanded to an full Command Name and not case corrected.

    Use -Verbose to see actions taken!

.EXAMPLE
   
   # Correct the Powershell code out of a given String
   Format-BoPsCodeCasing -Code 'if(-Not Test-path -Path "\\127.0.0.1\Share") { Connect-SmbShare "\\127.0.0.1\Share" }' -Verbose

.EXAMPLE

    # Correct the Powershell code out of a File named 'Get-RegistrySDDescriptor.ps1' ( use Get-Content with -Raw !!!!!)
    Format-BoPsCodeCasing -Code (Get-Content -Path 'D:\PowerShell\src\Security\Get-RegistrySDDescriptor.ps1' -Raw)

.EXAMPLE

    # Correct the Powershell code out of a File named 'Get-RegistrySDDescriptor.ps1' ( use Get-Content with -Raw !!!!!)
    # Save changes to a new File with Out-File
    Format-BoPsCodeCasing -Code (Get-Content -Path 'D:\PowerShell\src\Security\Get-RegistrySDDescriptor.ps1' -Raw) | Out-File -FilePath 'D:\PowerShell\src\Security\Get-RegistrySDDescriptor-Beau.ps1'

.OUTPUTS
   String of changed Code Text

.NOTES
   TODO:
   Handle TypesNames Like [int]
#>
    [CmdletBinding()]
    Param(
        
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$Code
    )

    Begin {
        # put Code Text into StringBuilder to process String operations faster
        $StringBuilder = [System.Text.StringBuilder]$Code

        # Put all Command names out of this Runspace into an Hashtable
        # to access the Command names fast over the Key (.ToLower())
        # TODO: this takes long time, so do it only once in a Modulevariable and not in each Function, annyway ... after new loaded modules added commands, this has to run again!
        $CommandsHash = @{}
        Get-Command -CommandType 'All' -All | Where-Object { $_.CommandType -ne 'Alias' } | ForEach-Object { $CommandsHash.($_.Name.ToLower()) = $_.Name }

        $ShortTypeNames = @{
            Boolean = 'Bool'
            Single = 'Float'
            Int32 = 'Int'
            Int64 = 'Long'
        }

    }

    Process {
        
        Try {
            
            $Tokens = $null
            $Errors = $null # TODO: Process parsing Erros (currently we do not care here)
            $Null = [System.Management.Automation.Language.Parser]::ParseInput(($StringBuilder.Tostring()), [ref]$Tokens, [ref]$Errors)

            ForEach($Token in $Tokens) {

                # making String replacements with strings of same length,
                # which not change the Text Offsets
        
                # Keywords having the same Text like the Kind.ToString() 
                # so replacement is easy here
    
                # test if Text is equal to the Kind
                If($Token.Text -ieq $Token.Kind.ToString()) {
                    # because a replace cost much, we replace only if casing is different
                    If($Token.Text -cne $Token.Kind.ToString()) {

                        Write-Verbose "Replacing $($Token.Text) with $($Token.Kind.ToString())" 
                        $Null = $StringBuilder.Remove($Token.Extent.StartOffset,($Token.Extent.EndOffset - $Token.Extent.StartOffset))
                        $Null = $StringBuilder.Insert($Token.Extent.StartOffset, $Token.Kind.ToString())
                    } Else {
                        Write-Verbose "No need to replace $($Token.Text) with $($Token.Kind.ToString())" 
                    }
                }
    

                # Commands like type of Cmdlet,Application,Function ect.... NO Alias!
                If($Token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName)) {
        
                    #Try to find the Command Name in the $CommandsHash
                    [String]$Value = $CommandsHash[($Token.Text.ToLower())]

        
                    If(-Not [String]::IsNullOrEmpty($Value)) {
                        # because a replace cost much, we replace only if casing is different
                        If($Token.Text -cne $Value) {
                            Write-Verbose "Replacing $($Token.Text) with $Value" 
                            $Null = $StringBuilder.Remove($Token.Extent.StartOffset,($Token.Extent.EndOffset - $Token.Extent.StartOffset))
                            $Null = $StringBuilder.Insert($Token.Extent.StartOffset, $Value)
                        } Else {
                            Write-Verbose "No need to replace $($Token.Text) with $Value" 
                        }

                    } Else {
                        
                        Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Command name '$($Token.Text)' not found!"
                    }

                }

                # TypeNames
                If(($Token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::TypeName) -and (-Not $Token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::AttributeName)))) {

                    $ReplaceText = $Null
                    
                    # try to get the Type out of the Token.Text
                    Try {
                        $Type = $Null
                        $Type = [Scriptblock]::Create(('[' + $Token.Text + ']')).Invoke()
                    } Catch {
                        Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Can not resolve .NET Type [$($Token.Text)]"
                    }

                    If($Null -ne $Type ) {

                        $ShortName = $Null
                        $ShortName = $ShortName = $ShortTypeNames[($Type.Name)]

                        # because PowerShell allows to drop the first Namespace element
                        # we create an Name without the first Namespace element
                        # eg. System.Text.StringBuilder is resolved to Text.StringBuilder
                        $Array = $Type.FullName.Split('.')
                        $DroppedNamespaceName = $Array[1..($Array.count -1)] -join '.'
                                                
                        $Replace = $True

                        Switch ($Token.Text) {
                                                        
                            {$_ -ieq $DroppedNamespaceName} { $ReplaceText = $DroppedNamespaceName }
                            
                            {$_ -ieq $Type.Name} { $ReplaceText = $Type.Name }
                            
                            {$_ -ieq  $Type.FullName} { $ReplaceText = $Type.FullName }

                            {$_ -ieq $ShortName} {$ReplaceText = $ShortName}

                            Default {
                                $ReplaceText = $Null
                                Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); No match of .NET Type [$($Token.Text)]"
                                $Replace = $False
                            }
                        }

                        # because a replace cost much, we replace only if casing is different
                        If($Replace -and ($Token.Text -cne $ReplaceText)) {

                            Write-Verbose "Replacing [$($Token.Text)] with [$ReplaceText]" 
                            $Null = $StringBuilder.Remove($Token.Extent.StartOffset,($Token.Extent.EndOffset - $Token.Extent.StartOffset))
                            $Null = $StringBuilder.Insert($Token.Extent.StartOffset, $ReplaceText)
                        } Else {
                            Write-Verbose "No need to replace .Net Type [$($Token.Text)] with [$ReplaceText])" 
                        }

                        }

                }

               # Attribute Names ; AttributeName
               If($Token.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::AttributeName)) {

                    $ReplaceText = $Null
                    
                    # try to get the Type out of the Token.Text
                    Try {
                        $Type = $Null
                        $Type = [Scriptblock]::Create(('[' + $Token.Text + ']')).Invoke()
                    } Catch {
                        Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Can not resolve .NET Attribute [$($Token.Text)Attribute]"
                    }

                    If($Null -ne $Type ) {

                        $ReplaceText = $Null
                        If ($Type.Name.EndsWith('Attribute',$True,$Null)) {
                          $ReplaceText = $Type.Name.Substring(0,('CmdletBindingAttribute'.Length - 9))  
                        }

                        # TODO: Do we need Namspaces for Attributes here ? 

                        If ($ReplaceText -ieq $Token.Text) {
                            # because a replace cost much, we replace only if casing is different
                            If($Replace -and ($Token.Text -cne $ReplaceText)) {

                                Write-Verbose "Replacing Attribute $($Token.Text) with $ReplaceText" 
                                $Null = $StringBuilder.Remove($Token.Extent.StartOffset,($Token.Extent.EndOffset - $Token.Extent.StartOffset))
                                $Null = $StringBuilder.Insert($Token.Extent.StartOffset, $ReplaceText)
                            } Else {
                                Write-Verbose "No need to replace Attribute $($Token.Text) with $ReplaceText" 
                            }
                        }

                    }

                } 
                
            }

            Write-Output $StringBuilder.ToString()

        } Catch {
            Write-Error -ErrorRecord $_
        }
    }
}


<#

 Format-BoPsTokenCodeCasing -Code (Get-Content -Path 'C:\temp\Attribs.ps1' -Raw) -Verbose

 Format-BoPsTokenCodeCasing -Code (Get-Content -Path 'D:\SVNRepository\PowerShell\Entwicklung\Security\Get-Set-RegistrySDDescriptor.ps1' -Raw) -Verbose | Out-File -FilePath 'D:\SVNRepository\PowerShell\Entwicklung\Security\Get-Set-RegistrySDDescriptor-beau.ps1'
#>