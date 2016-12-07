Param(
  # log file to monitor
  [Parameter(Mandatory=$True)]
  [string]$logfile,
  
  # bookmark file (holds last checked line number)
  [Parameter(Mandatory=$True)]
  [string]$bookmarkfile,
  
  # flag file - all found errors are stored here (delete to clear alert )
  [Parameter(Mandatory=$True)]
  [string]$flagfile,
  
  # powershell regular multiline expression pattern 
  [Parameter(Mandatory=$True)]
  [regex]$pattern
)


function how_many_lines {
  # checks how many lines are in logfile
  param ( [string] $logFile )
  $count = 0
  If (Test-Path $logFile){
  Get-Content -Path $logFile -ReadCount 100 |% { $count += $_.Count }
  } else {
    write-host "FAIL! unable to find $logFile"
    exit 2
  }
  return ($count)
}


function load_previous_lines{
  # loads number from file
  param ( [string] $bookmarkfile )
  $lines=0
  If (Test-Path($bookmarkfile)){
    $strlines = get-content $bookmarkfile  -totalcount 1
    $lines = [convert]::ToInt32($strlines, 10)
  }
  return($lines)
}


function save_previous_lines{
  # saves number to file 
  param ( [string] $bookmarkfile, 
  [int32] $count )
  $count >  $bookmarkfile
}

# load how many lines we have analized in previous run from bookmarkfile
$oldlines = load_previous_lines -bookmarkfile $bookmarkfile
# check how many lines are now in logfile
$currentlines = how_many_lines -logfile $logfile

# we assume number of lines changed since previous run 
# possible bug - if file is recreated, and coincidentally has same amount of lines as during previous run we will miss
# all entries until last line from previous run 
if ( $currentlines -ne $oldlines) {
  # current lines bigger than in previous lines (file grew )
  if ( $currentlines -gt $oldlines ){
    $lastlines = $currentlines - $oldlines
    [string]$found=get-Content -Path $logFile -tail $lastlines
  # current lines smaller than in previous run (new file )
  } elseif ( $oldlines -gt $currentlines) {
    [string]$found=get-Content -Path $logFile
  }
  $regex.Matches($found) | foreach-object {$_.Value} >> $flagfile
}

# store number of lines we have analized 
save_previous_lines -bookmarkfile $bookmarkfile -count $currentlines

# existence of flagfile suggests there were errors found in this(or previous) runs
If (Test-Path($flagfile)){
  $exitcode=2
  write-host "FAIL: $flagfile exists!"
  Get-Content -Path $flagfile | write-host
} else {
  $exitcode=0
  write-host "OK"
}

exit $exitcode
