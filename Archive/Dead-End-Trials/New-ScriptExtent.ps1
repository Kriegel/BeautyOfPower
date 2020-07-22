[String]$ScriptName,
[int]$scriptLineNumber,
[int]$offsetInLine,
[String]$line,
[String]$fullScript




$InternalStartScriptPosition = $Token.Extent.StartScriptPosition
$InternalEndScriptPosition = $Token.Extent.EndScriptPosition

$StartScriptPosition = New-Object System.Management.Automation.Language.ScriptPosition -ArgumentList $InternalStartScriptPosition.File,$InternalStartScriptPosition.LineNumber,$InternalStartScriptPosition.Offset,$InternalStartScriptPosition.Line,$Null
$EndScriptPosition = New-Object System.Management.Automation.Language.ScriptPosition -ArgumentList $InternalEndScriptPosition.File,$InternalEndScriptPosition.LineNumber,$InternalEndScriptPosition.Offset,$InternalEndScriptPosition.Line,$Null

New-Object System.Management.Automation.Language.ScriptExtent -ArgumentList $StartScriptPosition,$EndScriptPosition