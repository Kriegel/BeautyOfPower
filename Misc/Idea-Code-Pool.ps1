# TextInfo.ToTitleCase() Method is to Capitalize the first letter of each word
# TextInfo can be found in the CultureInfo Object
$TextInfo = ([System.Globalization.CultureInfo]::InvariantCulture).TextInfo


# get official type shortcut / accelerator list from PowerShell
$PsAccelerators = ForEach ($Key in ([psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get).Keys) {
    # Capitalize the first letter of each word
    $TextInfo.ToTitleCase($Key)
}
$PsAccelerators


# Get parameter Informations
$Dict = (Get-Command Get-ChildItem).Parameters
ForEach($Key in $Dict.Keys) {$Dict[$Key] }