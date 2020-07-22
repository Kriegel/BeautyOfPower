<#
.synopsis
   kurzbeschreibung
.description
   lange beschreibung
.example
   beispiel für die verwendung dieses cmdlets
.example
   another example of how to use this cmdlet
.inputs
   inputs to this cmdlet (if any)
.outputs
   output from this cmdlet (if any)
.notes
   allgemeine hinweise
.component
   the component this cmdlet belongs to
.role
   the role this cmdlet belongs to
.functionality
   the functionality that best describes this cmdlet
#>
function verb-noun {
    [cmdletbinding(defaultparametersetname='parameter set 1', 
                  supportsshouldprocess=$true, 
                  positionalbinding=$false,
                  helpuri = 'http://www.microsoft.com/',
                  confirmimpact='medium')]
    [alias()]
    [outputtype([string])]
    param
    (
        # hilfebeschreibung zu param1
        [parameter(mandatory=$true, 
                   valuefrompipeline=$true,
                   valuefrompipelinebypropertyname=$true, 
                   valuefromremainingarguments=$false, 
                   position=0,
                   parametersetname='parameter set 1')]
        [validatenotnull()]
        [validatenotnullorempty()]
        [validatecount(0,5)]
        [validateset("sun", "moon", "earth")]
        [alias("p1")] 
        $param1,

        # hilfebeschreibung zu param2
        [parameter(parametersetname='parameter set 1')]
        [allownull()]
        [allowemptycollection()]
        [allowemptystring()]
        [validatescript({$true})]
        [validaterange(0,5)]
        [int]
        $param2,

        # hilfebeschreibung zu param3
        [parameter(parametersetname='another parameter set')]
        [validatepattern("[a-z]*")]
        [validatelength(0,15)]
        [string]
        $param3
    )

    begin {
    }
    process {
        if ($pscmdlet.shouldprocess("target", "operation")) {


  # get a hashtable of all files of size greater 0
  # grouped by their length
  
  
  # enumerate all files recursively
  # call scriptblocks directly and pipe them together
  # this is by far the fastest way and much faster than
  # using foreach-object:
  & { 
    try {
      # try and use the fast api way of enumerating files recursively
      # this fails whenever there is any "access denied" errors
      write-progress -activity 'acquiring files' -status 'fast method'
      [io.directoryinfo]::new($path).getfiles('*', 'alldirectories')
    }
    catch {
      # use powershell's own (slow) way of enumerating files if any error occurs:
      write-progress -activity 'acquiring files' -status 'falling back to slow method'
      get-childitem -path $path -file -recurse -erroraction ignore
    }
  } | 
  # exclude empty files:
  # use direct process blocks with if (which is much faster than where-object):
  & {
    process {
      # if the file has content...
      if ($_.length -gt 0) {
        # let it pass through:
        $_
      }
    }
  } | 
  # group files by length, and return only files where there is at least one
  # other file with same size
  # use direct scriptblocks with own hashtable (which is much faster than group-object)
  & { 
    begin    # start with an empty hashtable { $hash = @{} } 

    process { 
      # group files by their length
      # (use "length" as hashtable key)
      $file = $_
      $key = $file.length.tostring()
      
      # if we see this key for the first time, create a generic
      # list to hold group items, and store fileinfo objects in this list
      # (specialized generic lists are faster than arraylist):
      if ($hash.containskey($key) -eq $false) {
        $hash[$key] = [collections.generic.list[system.io.fileinfo]]::new()
      }
      # add file to appropriate hashtable key:
      $hash[$key].add($file)
    } 
  
    end { 
      # return only the files from groups with at least two files
      # (if there is only one file with a given length, then it 
      # cannot have any duplicates for sure):
      foreach($pile in $hash.values) {
        # are there at least 2 files in this pile?
        if ($pile.count -gt 1) {
          # yes, add it to the candidates
          $pile
        }
      }
    } 
  } | 
  # calculate the number of files to hash
  # collect all files and hand over en-bloc
  & {
    end { ,@($input) }
  } |
  # group files by hash, and return only hashes that have at least two files:
  # use a direct scriptblock call with a hashtable (much faster than group-object):
  & {
    begin {
      # start with an empty hashtable
      $hash = @{}
      
      # since this is a length procedure, a progress bar is in order
      # keep a counter of processed files:
      $c = 0
    }
      
    process {
      $totalnumber = $_.count
      foreach($file in $_) {
      
        # update progress bar
        $c++
      
        # update progress bar every 20 files:
        if ($c % 20 -eq 0 -or $file.length -gt 100mb) {
          $percentcomplete = $c * 100 / $totalnumber
          write-progress -activity 'hashing file content' -status $file.name -percentcomplete $percentcomplete
        }
      
        # use the file hash of this file plus file length as a key to the hashtable
        # use the fastest algorithm sha1, and use partial hashes for files larger than 100kb:
        $buffersize = [math]::min(100kb, $maxfilesize)
        $result = get-psonefilehash -startposition 1kb -length $maxfilesize -buffersize $buffersize -algorithmname sha1 -path $file.fullname
        
        # add a "p" to partial hashes:
        if ($result.ispartialhash) {
          $partialhash = 'p'
        }
        else {
          $partialhash = ''
        }
        
        
        $key = '{0}:{1}{2}' -f $result.hash, $file.length, $partialhash
      
        # if we see this key the first time, add a generic list to this key:
        if ($hash.containskey($key) -eq $false) {
          $hash.add($key, [collections.generic.list[system.io.fileinfo]]::new())
        }
      
        # add the file to the approriate group:
        $hash[$key].add($file)
      }
    }
      
    end {
      # remove all hashtable keys with only one file in them
      
      
      
      # do a detail check on partial hashes
      if ($testpartialhash) {
        # first, clone the list of hashtable keys
        # (we cannot remove hashtable keys while enumerating the live
        # keys list):
        $keys = @($hash.keys).clone()
        $i = 0
        foreach($key in $keys) {
          $i++
          $percentcomplete = $i * 100 / $keys.count
          if ($hash[$key].count -gt 1 -and $key.endswith('p')) {
            foreach($file in $hash[$key]) {
              write-progress -activity 'hashing full file content' -status $file.name -percentcomplete $percentcomplete
              $result = get-filehash -path $file.fullname -algorithm sha1
              $newkey = '{0}:{1}' -f $result.hash, $file.length
              if ($hash.containskey($newkey) -eq $false) {
                $hash.add($newkey, [collections.generic.list[system.io.fileinfo]]::new())
              }
              $hash[$newkey].add($file)
            }
            $hash.remove($key)
          }
        }
      }
      
      # enumerate all keys...
      $keys = @($hash.keys).clone()
      
      foreach($key in $keys) {
        # ...if key has only one file, remove it:
        if ($hash[$key].count -eq 1) {
          $hash.remove($key)
        }
      }
       
      
       
      # return the hashtable with only duplicate files left:
      $hash
    }
  }

        }
    }
    end {
    }
}
 