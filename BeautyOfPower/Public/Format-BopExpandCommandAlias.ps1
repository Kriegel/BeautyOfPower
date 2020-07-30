Function Format-BopExpandCommandAlias {
<#
.SYNOPSIS
    Format PowerShell code to expand command Alias to their respective command definitions

.DESCRIPTION
    Format PowerShell code to expand command Alias to their respective command definitions

    Best practice is that aliases aliases should be avoided and not be used in blogs, in help, in examples,
    or in any shared scripts and commands.
    They create an extra layer of confusion for beginners and they’re an obstacle for
    anyone who needs to maintain the script.
    Especially in production code where readability, and easy comprehension of the code are
    much more important then the usage of aliases.

    On Linux / macOS, the "convenience aliases" for the basic commands
    ls, cp, mv, rm, cat, man, mount, ps and other have been removed.

    So alias mappings will not be consistent across different Operatin Systems (OS).

    This poses significant issues in the likely scenario where a script was edited
    on one OS but is then being processed with this Function on an other OS.

    List of Alias that are NOT expanded by default:

        ac, asnp, cat, CFS, compare, cp, cpp, curl, diff, epsn, gcb, gin, gsnp,
        gsv, gwmi, ipsn, ise, iwmi, lp, ls, man, mount, mv, npssc, ogv, ps, rm,
        rmdir, rsnp, rujb, rwmi, sasv, scb, shcm, sleep, sort, spsv, start, stz,
        sujb, swmi, tee, trcm, wget, write

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
        [PsObject]$BopToken,

        [Switch]$CaseSensitiv,

        [Switch]$IncludeAll
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        $ExcludeList = @('ac',
                        'asnp',
                        'cat',
                        'CFS',
                        'compare',
                        'cp',
                        'cpp',
                        'curl',
                        'diff',
                        'epsn',
                        'gcb',
                        'gin',
                        'gsnp',
                        'gsv',
                        'gwmi',
                        'ipsn',
                        'ise',
                        'iwmi',
                        'lp',
                        'ls',
                        'man',
                        'mount',
                        'mv',
                        'npssc',
                        'ogv',
                        'ps',
                        'rm',
                        'rmdir',
                        'rsnp',
                        'rujb',
                        'rwmi',
                        'sasv',
                        'scb',
                        'shcm',
                        'sleep',
                        'sort',
                        'spsv',
                        'start',
                        'stz',
                        'sujb',
                        'swmi',
                        'tee',
                        'trcm',
                        'wget',
                        'write'
                    )

        # extract all Alias-Command  from Command Hashtable
        # the key in the Hashtable is converted to lower cas to find alias case insensitive
        $AliasHashLowerKeys = @{}
        ForEach ($Key in $BopCommandHashList.Keys) {
            # each value of a Key can contain an array of CommandInfo Objects
            # so we unwind the array with the help of the pipeline and so
            # we can process each single command
            $BopCommandHashList[$Key] |
                # using fast scriptblock filtering instead of Where-Object:
                & { Process { If ($_.CommandType -eq 'Alias') {

                            # because we converte the Keys to Lower
                            # we have to check for double keys
                            If($null -eq $AliasHashLowerKeys[($Key.ToLower())]) {
                                # lower key was not in hash, add it
                                $AliasHashLowerKeys[($Key.ToLower())] = $BopCommandHashList[$Key]
                            }
                            Else {
                                # lower key was already in hash!

                                # write warnig only in case insensitive mode
                                If(-not $CaseSensitiv.IsPresent) {
                                    Write-Warning "$MyCommandName; Alias $Key is case sensitiv! Merging all Aliases to one!"
                                }
                                # merging lower alias names
                                ($AliasHashLowerKeys[($Key.ToLower())]).Add(($BopCommandHashList[$Key]))
                            }
                        }
                    }
                }
        }


    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {

                # all tokens which not have the CommandName Flag
                # are returned immediately
                # and loop continues with next Token
                # for simpleness and speed reasond I do not use Select-BopToken here
                If(-Not ($Tok.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName))) {
                    Write-Verbose "$MyCommandName; $($Tok.Text) is no CommandName ; Continue"
                    Write-Output $Tok
                    Continue
                 }

                # return all commands that are not in our Alias array immediately
                If($null -eq $AliasHashLowerKeys[($Tok.Text.Tolower())]) {
                    Write-Output $Tok
                    Continue
                }

                # return all Alias that are excluded immediately
                If(-Not $IncludeAll.IsPresent) {
                    If($ExcludeList -icontains $Tok.Text) {
                        Write-Verbose "$MyCommandName; Skipping excluded alias $($Tok.Text)"
                        Write-Output $Tok
                        Continue
                    }
                }

                If(-Not $CaseSensitiv.IsPresent) {

                    If(($AliasHashLowerKeys[($Tok.Text.Tolower())]).Count -eq 1) {
                        $Tok.Surrogate = (($AliasHashLowerKeys[($Tok.Text.Tolower())])[0]).Definition
                        Write-Verbose "$MyCommandName; Expanding Alias $($Tok.Text) to $($Tok.Surrogate)"
                        Write-Output $Tok
                        Continue
                    }
                    Else {

                        # There are more then one Command that are having this alias

                        # TODO: Write better handling here
                        ForEach ($Cmd in ($AliasHashLowerKeys[($Tok.Text.Tolower())])) {
                            Write-Warning "$MyCommandName; Alias can result in multiple Commands!`nAlias '$($Tok.Text)' has equivalent Command $($Cmd.Name) with CommandType $($Cmd.CommandType) Source $($Cmd.Source)"
                        }
                        Write-Output $Tok
                    }
                }
                Else {

                    If(($BopCommandHashList[($Tok.Text)]).Count -eq 1) {
                        $Tok.Surrogate = (($BopCommandHashList[($Tok.Text)])[0]).Definition
                        Write-Verbose "$MyCommandName; Expanding Alias $($Tok.Text) to $($Tok.Surrogate)"
                        Write-Output $Tok
                        Continue
                    }
                    Else {

                        # There are more then one Command that are having this alias

                        # TODO: Write better handling here
                        ForEach ($Cmd in ($BopCommandHashList[($Tok.Text)])) {
                            Write-Warning "$MyCommandName; Alias can result in multiple Commands!`nAlias '$($Tok.Text)' has equivalent Command $($Cmd.Name) with CommandType $($Cmd.CommandType) Source $($Cmd.Source)"
                        }
                        Write-Output $Tok
                    }
                }
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}