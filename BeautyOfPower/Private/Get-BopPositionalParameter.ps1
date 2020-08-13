Function Get-BopPositionalParameter {
<#
.SYNOPSIS
    Returns Positional Parameters from a CommandInfo Object

.DESCRIPTION
    Returns Positional Parameters from a CommandInfo Object

    A Parameter can have different Positions in different Parameter Sets
    This Function only returns Parameter which have the same Position in all Parameter Sets

    If you spicify a Name of a ParameterSet, this Function returns only the Positional Parameters out of this ParameterSet

.EXAMPLE

    Get-PositionalParameter -CommandInfo (Get-Command -Name 'Get-WmiObject')

.EXAMPLE

    Get-Command -CommandType 'Cmdlet' | ForEach-Object {
        Get-PositionalParameter -CommandInfo $_
    }

.EXAMPLE

    Get-PositionalParameter -CommandInfo (Get-Command -Name 'Get-ChildItem') -ParameterSetName 'Items' -Verbose

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
        [System.Management.Automation.CommandInfo]$CommandInfo,


        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=1
        )]
        [ValidateNotNullOrEmpty()]
        # spicify the Name of the ParameterSet, this returns only the Positional Parameters out of this ParameterSet
        [String]$ParameterSetName
    )

    process {

        Try {

            $ParameterSetValuesArray = [System.Collections.ArrayList]@()
            $PosParamArray = [System.Collections.ArrayList]@()
            $PosParamNeArray = [System.Collections.ArrayList]@()

            $ParametersetNames  = $CommandInfo.Parameters.Values | ForEach-Object { $_.ParameterSets.Keys } | Select-Object -Unique

            Write-Verbose "ParametersetNames:`n$($ParametersetNames -join ', ')"

            ForEach ($Param in $CommandInfo.Parameters.Values) {

                $ParameterSetValuesArray.Clear()

                ForEach($Key in $Param.ParameterSets.Keys) {

                    # if ParameterSetName is given process only parameters in this ParameterSet
                    If(-not ([String]::IsNullOrEmpty($ParameterSetName))) {

                        # Parameter in Parameteset '__AllParameterSets' belongs to every Parameterset
                        # do not skip this Parameterset
                        If($Key -ne '__AllParameterSets' -and $Key -ne $ParameterSetName) {

                            # ParameterSet is NOT in given ParameterSetName skipping ParameterSet
                            #If($Key -ne $ParameterSetName) {
                                Continue
                            #}
                        }
                    }


                    [Array]$ParamSetValues = $Param.ParameterSets[$Key] | & { Process { If ($_.Position -ge 0) { $_ }}}

                    If ($null -ne $ParamSetValues) {
                        $null = $ParameterSetValuesArray.AddRange($ParamSetValues)
                    }
                }

                If($ParameterSetValuesArray.Count -eq 0) {Continue}

                $Position = $null
                $PositionsEqual = $false

                ForEach ($ParamSetValue in $ParamSetValues) {

                If($null -eq $Position) {
                    $Position = $ParamSetValue.Position
                    $PositionsEqual = $true
                }
                Else {
                    If($Position -ne $ParamSetValue.Position) {
                        $PositionsEqual = $false
                        Write-Warning "Position differs in Parameter Sets for Command named '$($CommandInfo.Name)' and Parameter named '$($Param.Name)' Position $Position -ne $($ParamSetValue.Position)"
                        $Position = $ParamSetValue.Position
                    }
                }


                }

                If($PositionsEqual) {
                $null = $PosParamArray.Add(([PSCustomObject]@{
                    CommandName = $CommandInfo.Name
                    ModuleName = $CommandInfo.ModuleName
                    ParameterName = $Param.Name
                    ParameterPosition = $Position
                    ParameterMetadata = $Param
                    isSingelPosition = $true
                }))
            }
            }

            # Test if 2 Parameters having the same Position
            ForEach ($PosParam in $PosParamArray) {

                ForEach ($Item in $PosParamArray) {
                    # skipping self-comparison
                    If($PosParam.ParameterName -eq $Item.ParameterName) {Continue}

                    If($PosParam.ParameterPosition -eq $Item.ParameterPosition) {
                    Write-Warning "Command named '$($CommandInfo.Name)' Parameters '$($PosParam.ParameterName)' and '$($Item.ParameterName)' having the same Position $($PosParam.ParameterPosition) in Parameter Sets! Removing from List!"

                    # set flags for both parameter to false
                    $PosParam.isSingelPosition = $Item.isSingelPosition = $false
                    }
                }
            }

            ForEach ($PosParam in $PosParamArray) {
            If($PosParam.isSingelPosition){
                $null = $PosParamNeArray.Add($PosParam)
            }
            }

            If($PosParamNeArray.Count -gt 0) {
                Write-Output ($PosParamNeArray.ToArray())
            }
            Else {
            Write-Output $null
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}