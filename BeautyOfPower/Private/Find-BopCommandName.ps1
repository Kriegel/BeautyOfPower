Function Find-BopCommandName {
 <#
.SYNOPSIS
    Find a CommandName in the Module Private case sensitive HashTable $BopCommandHashList

.DESCRIPTION
    Find a CommandName in the Module Private case sensitive HashTable $BopCommandHashList

    The case sensitive HashTable $BopCommandHashList is filled by the Command Get-BopCommandNames
    See there for further reading.

.NOTES
    Author: Peter Kriegel
#>
    [CmdletBinding()]
    Param(

        [Parameter(Mandatory =$true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [String]$Name
    )

    Process {

        $ResultObject = [PsCustomObject]@{
            CommandName = $Name
            Surrogate = ''
            EquivalentFound = $false
            IsCasingEqual = $false
            IsWindows = ($env:OS -iLike '*Windows*')
            MultipleValues = @()
        }


        Try {

            #Try to find the Command Name in the $BopCommandHashList
            # this is case sensitiv !!!
            # and returns a List!
            $CmdList = $BopCommandHashList[$Name]

            If($CmdList.Count -eq 1) {
                # command has already the correct casing and exist only on time
                # nothing to change
                $ResultObject.Surrogate = $CmdList[0].Name
                $ResultObject.IsCasingEqual = $true
                $ResultObject.EquivalentFound = $true

                Return $ResultObject
            }

            If($CmdList.Count -eq 0) {
                $CmdList = [System.Collections.ArrayList]@()
                # no command found trying case insensitive
                ForEach ($Key in $BopCommandHashList.Keys) {
                    If($Key.Tolower() -eq $Name.Tolower()) {
                        $Null = $CmdList.AddRange($BopCommandHashList[$Key])
                    }
                }
            }

            If($CmdList.Count -eq 1) {
                $ResultObject.Surrogate = $CmdList[0].Name
                $ResultObject.IsCasingEqual = $false
                $ResultObject.EquivalentFound = $true

                Return $ResultObject
            }

            If($CmdList.Count -gt 1) {
                # TODO: Write better handling here
                ForEach ($Cmd in $CmdList) {
                    Write-Warning "$($PSCmdlet.MyInvocation.MyCommand.Name); Command has multiple equivalents! '$Name' has equivalent $($Cmd.Name) with CommandType $($Cmd.CommandType) Source $($Cmd.Source)"
                    $ResultObject.Surrogate = ''
                    $ResultObject.IsCasingEqual = $false
                    $ResultObject.MultipleValues = $CmdList

                    Return $ResultObject
                }
            }

        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}