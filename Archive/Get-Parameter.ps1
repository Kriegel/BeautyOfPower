Function Get-Parameter {
<#PSScriptInfo

.VERSION 2.9

.GUID f734fc6a-79e6-4b9d-8e9c-79dffca02ed7

.AUTHOR Joel Bennett, Jason Archer, Shay Levy, Hal Rottenberg, Oisin Grehan

.COMPANYNAME PoshCode.org

.COPYRIGHT All rights released.

.TAGS Parameter, PoshCode

.LICENSEURI http://creativecommons.org/publicdomain/zero/1.0/

.PROJECTURI http://poshcode.org/5929

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

#Requires -version 2.0

<#
  .Synopsis
    Enumerates the parameters of one or more commands    
  .Description
    Lists all the parameters of a command, by ParameterSet, including their aliases, type, etc.

    By default, formats the output to tables grouped by command and parameter set
  .Example
    Get-Command Select-Xml | Get-Parameter
  .Example
    Get-Parameter Select-Xml
  .Notes
    With many thanks to Hal Rottenberg, Oisin Grehan and Shay Levy

    Version 0.80 - April 2008 - By Hal Rottenberg http://poshcode.org/186
    Version 0.81 - May 2008 - By Hal Rottenberg http://poshcode.org/255
    Version 0.90 - June 2008 - By Hal Rottenberg http://poshcode.org/445
    Version 0.91 - June 2008 - By Oisin Grehan http://poshcode.org/446
    Version 0.92 - April 2008 - By Hal Rottenberg http://poshcode.org/549
                - ADDED resolving aliases and avoided empty output
    Version 0.93 - Sept 24, 2009 - By Hal Rottenberg http://poshcode.org/1344
    Version 1.0  - Jan 19, 2010 - By Joel Bennett http://poshcode.org/1592
                - Merged Oisin and Hal's code with my own implementation
                - ADDED calculation of dynamic paramters
    Version 2.0  - July 22, 2010 - By Joel Bennett http://poshcode.org/get/2005
                - CHANGED uses FormatData so the output is objects
                - ADDED calculation of shortest names to the aliases (idea from Shay Levy http://poshcode.org/1982,
                  but with a correct implementation)
    Version 2.1  - July 22, 2010 - By Joel Bennett http://poshcode.org/2007
                - FIXED Help for SCRIPT file (script help must be separated from #Requires by an emtpy line)
                - Fleshed out and added dates to this version history after Bergle's criticism ;)
    Version 2.2  - July 29, 2010 - By Joel Bennett http://poshcode.org/2030
                - FIXED a major bug which caused Get-Parameters to delete all the parameters from the CommandInfo
    Version 2.3  - July 29, 2010 - By Joel Bennett 
                - ADDED a ToString ScriptMethod which allows queries like:
                  $parameters = Get-Parameter Get-Process; $parameters -match "Name"
    Version 2.4  - July 29, 2010 - By Joel Bennett http://poshcode.org/2032
                - CHANGED "Name" to CommandName
                - ADDED ParameterName parameter to allow filtering parameters
                - FIXED bug in 2.3 and 2.2 with dynamic parameters
    Version 2.5  - December 13, 2010 - By Jason Archer http://poshcode.org/2404
                - CHANGED format temp file to have static name, prevents bloat of random temporary files
    Version 2.6  - July 23, 2011 - By Jason Archer http://poshcode.org/2815
                - FIXED miscalculation of shortest unique name (aliases count as unique names),
                  this caused some parameter names to be thrown out (like "Object")
                - CHANGED code style cleanup
    Version 2.7  - November 28, 2012 - By Joel Bennett http://poshcode.org/3794
                - Added * indicator on default parameter set.
    Version 2.8  - August 27, 2013 - By Joel Bennett http://poshcode.org/4438
                - Added SetName filter 
                - Add * on the short name in the aliases list (to distinguish it from real aliases)
                  FIXED PowerShell 4 Bugs:
                - Added PipelineVariable to CommonParameters
                  FIXED PowerShell 3 Bugs:
                - Don't add to the built-in Aliases anymore, it changes the command!
    Version 2.9  - July 13, 2015 - By Joel Bennett (This Version)
                - FIXED (hid) exceptions when looking for dynamic parameters
                - CHANGE to only search for provider parameters on Microsoft.PowerShell.Management commands (BUG??)
                - ADDED SkipProviderParameters switch to manually disable looking for provider parameters (faster!)
                - ADDED "Name" alias for CommandName to fix piping Get-Command output
#>

   [CmdletBinding(DefaultParameterSetName="ParameterName")]
   param(
      # The name of the command to get parameters for
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [Alias("Name")]
      [string[]]$CommandName,

      # The parameter name to filter by (allows Wilcards)
      [Parameter(Position = 2, ValueFromPipelineByPropertyName=$true, ParameterSetName="FilterNames")]
      [string[]]$ParameterName = "*",

      # The ParameterSet name to filter by (allows wildcards)
      [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName="FilterSets")]
      [string[]]$SetName = "*",

      # The name of the module which contains the command (this is for scoping)
      [Parameter(ValueFromPipelineByPropertyName = $true)]
      $ModuleName,

      # Skip testing for Provider parameters (will be much faster)
      [Switch]$SkipProviderParameters,

      # Forces including the CommonParameters in the output
      [switch]$Force
   )

   begin {
      $PropertySet = @( "Name",
         @{n="Position";e={if($_.Position -lt 0){"Named"}else{$_.Position}}},
         "Aliases", 
         @{n="Short";e={$_.Name}},
         @{n="Type";e={$_.ParameterType.Name}}, 
         @{n="ParameterSet";e={$paramset}},
         @{n="Command";e={$command}},
         @{n="Mandatory";e={$_.IsMandatory}},
         @{n="Provider";e={$_.DynamicProvider}},
         @{n="ValueFromPipeline";e={$_.ValueFromPipeline}},
         @{n="ValueFromPipelineByPropertyName";e={$_.ValueFromPipelineByPropertyName}}
      )
      function Join-Object {
         Param(
           [Parameter(Position=0)]
           $First,

           [Parameter(ValueFromPipeline=$true,Position=1)]
           $Second
         )
         begin {
           [string[]] $p1 = $First | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
         }
         process {
           $Output = $First | Select-Object $p1
           foreach ($p in $Second | Get-Member -MemberType Properties | Where-Object {$p1 -notcontains $_.Name} | Select-Object -ExpandProperty Name) {
              Add-Member -InputObject $Output -MemberType NoteProperty -Name $p -Value $Second.("$p")
           }
           $Output
         }
      }

      function Add-Parameters {
         [CmdletBinding()]
         param(
            [Parameter(Position=0)]
            [Hashtable]$Parameters,

            [Parameter(Position=1)]
            [System.Management.Automation.ParameterMetadata[]]$MoreParameters
         )

         foreach ($p in $MoreParameters | Where-Object { !$Parameters.ContainsKey($_.Name) } ) {
            Write-Debug ("INITIALLY: " + $p.Name)
            $Parameters.($p.Name) = $p | Select *
         }

         [Array]$Dynamic = $MoreParameters | Where-Object { $_.IsDynamic }
         if ($dynamic) {
            foreach ($d in $dynamic) {
               if (Get-Member -InputObject $Parameters.($d.Name) -Name DynamicProvider) {
                  Write-Debug ("ADD:" + $d.Name + " " + $provider.Name)
                  $Parameters.($d.Name).DynamicProvider += $provider.Name
               } else {
                  Write-Debug ("CREATE:" + $d.Name + " " + $provider.Name)
                  $Parameters.($d.Name) = $Parameters.($d.Name) | Select *, @{ n="DynamicProvider";e={ @($provider.Name) } }
               }
            } 
         }
      }

      ## Since you can't update format data without a file that has a ps1xml ending, let's make one up...
      $tempFile = "$([System.IO.Path]::GetTempPath())Get-Parameter.ps1xml"
      Set-Content $tempFile @'
<?xml version="1.0" encoding="utf-8" ?>
<Configuration>
   <Controls>
      <Control>
         <Name>ParameterGroupingFormat</Name>
          <CustomControl>
             <CustomEntries>
               <CustomEntry>
                  <CustomItem>
                     <Frame>
                       <LeftIndent>4</LeftIndent>
                       <CustomItem>
                          <Text>Command: </Text>
                          <ExpressionBinding>
                             <ScriptBlock>"{0}/{1}" -f $(if($_.command.ModuleName){$_.command.ModuleName}else{$_.Command.CommandType.ToString()+":"}),$_.command.Name</ScriptBlock>
                          </ExpressionBinding>
                          <NewLine/>
                          <Text>Set:    </Text>
                          <ExpressionBinding>
                             <ScriptBlock>"$(if($_.ParameterSet -eq "__AllParameterSets"){"Default"}else{$_.ParameterSet})" + "$(if($_.ParameterSet.IsDefault){" *"})"</ScriptBlock>
                          </ExpressionBinding>
                          <NewLine/>
                       </CustomItem> 
                     </Frame>
                  </CustomItem>
               </CustomEntry>
             </CustomEntries>
         </CustomControl>
      </Control>
   </Controls>
   <ViewDefinitions>
      <View>
         <Name>ParameterMetadataEx</Name>
         <ViewSelectedBy>
           <TypeName>System.Management.Automation.ParameterMetadataEx</TypeName>
         </ViewSelectedBy>
         <GroupBy>
           <PropertyName>ParameterSet</PropertyName>
           <CustomControlName>ParameterGroupingFormat</CustomControlName>  
         </GroupBy>
         <TableControl>
            <TableHeaders>
               <TableColumnHeader>
                  <Label>Name</Label>
                  <Width>22</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>Aliases</Label>
                  <Width>12</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>Position</Label>
                  <Width>8</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>Mandatory</Label>
                  <Width>9</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>Pipeline</Label>
                  <Width>8</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>ByName</Label>
                  <Width>6</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>Provider</Label>
                  <Width>15</Width>
               </TableColumnHeader>
               <TableColumnHeader>
                  <Label>Type</Label>
               </TableColumnHeader>
            </TableHeaders>
            <TableRowEntries>
               <TableRowEntry>
                  <TableColumnItems>
                     <TableColumnItem>
                        <PropertyName>Name</PropertyName>
                     </TableColumnItem>
                     <TableColumnItem>
                        <PropertyName>Aliases</PropertyName>
                     </TableColumnItem>
                     <TableColumnItem>
                        <!--PropertyName>Position</PropertyName-->
                        <ScriptBlock>if($_.Position -lt 0){"Named"}else{$_.Position}</ScriptBlock>
                     </TableColumnItem>
                     <TableColumnItem>
                        <PropertyName>Mandatory</PropertyName>
                     </TableColumnItem>
                     <TableColumnItem>
                        <PropertyName>ValueFromPipeline</PropertyName>
                     </TableColumnItem>
                     <TableColumnItem>
                        <PropertyName>ValueFromPipelineByPropertyName</PropertyName>
                     </TableColumnItem>
                     <TableColumnItem>
                        <!--PropertyName>Provider</PropertyName-->
                        <ScriptBlock>if($_.Provider){$_.Provider}else{"All"}</ScriptBlock>
                     </TableColumnItem>
                     <TableColumnItem>
                        <PropertyName>Type</PropertyName>
                     </TableColumnItem>
                  </TableColumnItems>
               </TableRowEntry>
            </TableRowEntries>
         </TableControl>
      </View>
   </ViewDefinitions>
</Configuration>
'@

      Update-FormatData -Append $tempFile
   }

   process {
      foreach ($cmd in $CommandName) {
         if ($ModuleName) {$cmd = "$ModuleName\$cmd"}
         Write-Verbose "Searching for $cmd"
         $commands = @(Get-Command $cmd)

         foreach ($command in $commands) {
            Write-Verbose "Searching for $command"
            # resolve aliases (an alias can point to another alias)
            while ($command.CommandType -eq "Alias") {
              $command = @(Get-Command ($command.definition))[0]
            }
            if (-not $command) {continue}

            Write-Verbose "Get-Parameters for $($Command.Source)\$($Command.Name)"

            $Parameters = @{}

            ## We need to detect provider parameters ...
            $NoProviderParameters = !$SkipProviderParameters
            ## Shortcut: assume only the core commands get Provider dynamic parameters
            if(!$SkipProviderParameters -and $Command.Source -eq "Microsoft.PowerShell.Management") {
               ## The best I can do is to validate that the command has a parameter which could accept a string path
               foreach($param in $Command.Parameters.Values) {
                  if(([String[]],[String] -contains $param.ParameterType) -and ($param.ParameterSets.Values | Where { $_.Position -ge 0 })) {
                     $NoProviderParameters = $false
                     break
                  }
               }
            }

            if($NoProviderParameters) {
               if($Command.Parameters) {
                  Add-Parameters $Parameters $Command.Parameters.Values
               }
            } else {
               foreach ($provider in Get-PSProvider) {
                  if($provider.Drives.Length -gt 0) {
                     $drive = Get-Location -PSProvider $Provider.Name
                  } else {
                     $drive = "{0}\{1}::\" -f $provider.ModuleName, $provider.Name
                  }
                  Write-Verbose ("Get-Command $command -Args $drive | Select -Expand Parameters")

                  try {
                     $MoreParameters = (Get-Command $command -Args $drive).Parameters.Values
                  } catch {}
       
                  if($MoreParameters.Length -gt 0) {
                     Add-Parameters $Parameters $MoreParameters
                  }
               }
               # If for some reason none of the drive paths worked, just use the default parameters
               if($Parameters.Length -eq 0) {
                  if($Command.Parameters) {
                     Add-Parameters $Parameters $Command.Parameters.Values
                  }
               }
            }

            ## Calculate the shortest distinct parameter name -- do this BEFORE removing the common parameters or else.
            $Aliases = $Parameters.Values | Select-Object -ExpandProperty Aliases  ## Get defined aliases
            $ParameterNames = $Parameters.Keys + $Aliases
            foreach ($p in $($Parameters.Keys)) {
               $short = "^"
               $aliases = @($p) + @($Parameters.$p.Aliases) | sort { $_.Length }
               $shortest = "^" + @($aliases)[0]

               foreach($name in $aliases) {
                  $short = "^"
                  foreach ($char in [char[]]$name) {         
                     $short += $char
                     $mCount = ($ParameterNames -match $short).Count
                     if ($mCount -eq 1 ) {
                        if($short.Length -lt $shortest.Length) {
                           $shortest = $short
                        }
                        break
                     }
                  }
               }
               if($shortest.Length -lt @($aliases)[0].Length +1){
                  # Overwrite the Aliases with this new value
                  $Parameters.$p = $Parameters.$p | Add-Member NoteProperty Aliases ($Parameters.$p.Aliases + @("$($shortest.SubString(1))*")) -Force -Passthru
               }
            }

            # Write-Verbose "Parameters: $($Parameters.Count)`n $($Parameters | ft | out-string)"
            $CommonParameters = [string[]][System.Management.Automation.Cmdlet]::CommonParameters

            foreach ($paramset in @($command.ParameterSets | Select-Object -ExpandProperty "Name")) {
               $paramset = $paramset | Add-Member -Name IsDefault -MemberType NoteProperty -Value ($paramset -eq $command.DefaultParameterSet) -PassThru
               foreach ($parameter in $Parameters.Keys | Sort-Object) {
                  # Write-Verbose "Parameter: $Parameter"
                  if (!$Force -and ($CommonParameters -contains $Parameter)) {continue}
                  if ($Parameters.$Parameter.ParameterSets.ContainsKey($paramset) -or $Parameters.$Parameter.ParameterSets.ContainsKey("__AllParameterSets")) {
                     if ($Parameters.$Parameter.ParameterSets.ContainsKey($paramset)) {
                        $output = Join-Object $Parameters.$Parameter $Parameters.$Parameter.ParameterSets.$paramSet 
                     } else {
                        $output = Join-Object $Parameters.$Parameter $Parameters.$Parameter.ParameterSets.__AllParameterSets
                     }

                     Write-Output $Output | Select-Object $PropertySet | ForEach-Object {
                           $null = $_.PSTypeNames.Insert(0,"System.Management.Automation.ParameterMetadata")
                           $null = $_.PSTypeNames.Insert(0,"System.Management.Automation.ParameterMetadataEx")
                           # Write-Verbose "$(($_.PSTypeNames.GetEnumerator()) -join ", ")"
                           $_
                        } |
                        Add-Member ScriptMethod ToString { $this.Name } -Force -Passthru |
                        Where-Object {$(foreach($pn in $ParameterName) {$_ -like $Pn}) -contains $true} |
                        Where-Object {$(foreach($sn in $SetName) {$_.ParameterSet -like $sn}) -contains $true}

                  }
               }
            }
         }
      }
   }
}