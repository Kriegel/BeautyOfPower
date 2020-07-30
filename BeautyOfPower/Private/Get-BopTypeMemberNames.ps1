Function Get-BopTypeMemberNames {
<#
    TODO: Process ALL current loaded assemblies not only the well known.
#>


    [CmdletBinding()]
    Param()

    Process {

        # create an case insensitive HashSet[String]
        $Dictionary = New-Object 'System.Collections.Generic.Dictionary[[System.String],[System.String]]'

        # At first, we get MemberNames out of Types from mscore.lib (.Net Framework) or System.Private.CoreLib.dll (.NET core)
        $CoreLib = [Object].Assembly
        ForEach ($Type in $CoreLib.GetTypes()) {
            ForEach($Member in $Type.GetMembers()) {
                $LowerName = $Member.Name.Tolower()
                If($null -eq $Dictionary[$LowerName]) {
                    $Dictionary.Add($LowerName,($Member.Name))
                }
            }
        }

        # Second we pull all MemberNames out of Types from PowerShell agnostic assemblies
        $Assemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Fullname -like 'System.Management*'}
        ForEach ($Assembly in $Assemblies){
            ForEach ($Type in $Assembly.GetTypes()) {
                ForEach($Member in $Type.GetMembers()) {
                    $LowerName = $Member.Name.Tolower()
                    If($null -eq $Dictionary[$LowerName]) {
                        $Dictionary.Add($LowerName,($Member.Name))
                    }
                }
            }
        }

        # Third we pull all MemberNames out of Types from System assemblies
        $Assemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {($_.Fullname -like 'System*') -and ($_.Fullname -notlike 'System.Management*')}
        ForEach ($Assembly in $Assemblies){
            ForEach ($Type in $Assembly.GetTypes()) {
                ForEach($Member in $Type.GetMembers()) {
                    $LowerName = $Member.Name.Tolower()
                    If($null -eq $Dictionary[$LowerName]) {
                        $Dictionary.Add($LowerName,($Member.Name))
                    }
                }
            }
        }

        Write-Output $Dictionary
    }
}