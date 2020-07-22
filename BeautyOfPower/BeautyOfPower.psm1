#Requires -Version 3.0

Using NameSpace System.Management.Automation.Language

$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )


ForEach($import in @($Public + $Private)) {
    Try{
        . $import.fullname
    }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Creating a Hashtable which holds ALL command Info Objects (Alias,Function,Cmdlet, Application, ect.....)
# in Module (Private) Scope
###############################################################
# Note
# This is a performance bottlenecks only on loading the Module,
# but speeds up the execution during parsing
###############################################################
$BopCommandHashList = Get-BopCommandNames
$BopTypeMemberNamesDictionary = $null

Export-ModuleMember -Function $Public.Basename