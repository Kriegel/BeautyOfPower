Function Get-BopCommandNames {
<#
.SYNOPSIS
    Creating a Hashtable which holds ALL command Info Objects (Alias,Function,Cmdlet, Application, ect.....)

.DESCRIPTION
    Creating the Hashtable which holds ALL command Info Objects (Alias,Function,Cmdlet, Application, ect.....)
    Even Commands witch Modules are not loaded are catched
    The Key of the Hashtable are the Command Name (which is unique in a Hashtable)

    #############################################################
    The Keys are case Sensitiv! (to respect Linux and other case sensitive OS)
    ##############################################################

    The Value of each Key is an List of Commands found with the command Name
    This List should have in most cases only one entry
    in PowerShell Commands can be hidden or replaced by commands with the same name.
    The value List contains more then one element, if there is an other command with the same name
#>

    $HashTable = New-Object 'System.Collections.Hashtable'

    ForEach ($Cmd In Get-Command -All -CommandType 'All') {
        If($null -eq $HashTable[($Cmd.Name)]) {
            $NewList = [System.Collections.ArrayList]@()
            $null = $NewList.Add($CMD)
            $HashTable[($Cmd.Name)] = $NewList
        } Else {
            $null = ($HashTable[($Cmd.Name)]).Add($CMD)
        }
    }
        Write-Output $HashTable
}