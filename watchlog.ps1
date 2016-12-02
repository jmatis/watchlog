Param(
  [Parameter(Mandatory=$True)]
  [string]$logfile,
  
  [Parameter(Mandatory=$True)]
  [string]$bookmarkfile,
  
  [Parameter(Mandatory=$True)]
  [string]$flagfile,
  
  [Parameter(Mandatory=$True)]
  [string]$pattern
)

function how_many_lines {
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
  param ( [string] $bookmarkfile )
  $lines=0
  If (Test-Path($bookmarkfile)){
    $strlines = get-content $bookmarkfile  -totalcount 1
    $lines = [convert]::ToInt32($strlines, 10)
  }
  return($lines)
}

function save_previous_lines{
  param ( [string] $bookmarkfile, 
  [int32] $count )
  $count >  $bookmarkfile
}

$oldlines = load_previous_lines -bookmarkfile $bookmarkfile
$currentlines = how_many_lines -logfile $logfile

if ( $currentlines -ne $oldlines) {
  if ( $currentlines -gt $oldlines ){
    $lastlines = $currentlines - $oldlines
    $found=get-Content -Path $logFile -tail $lastlines 
  } elseif ( $oldlines -gt $currentlines) {
    $found=get-Content -Path $logFile
  }
  foreach ($line in $found) {
    if ( $line | select-string -pattern $pattern -quiet ) {
	  $line >> $flagfile
    }
  }
}

save_previous_lines -bookmarkfile $bookmarkfile -count $currentlines

If (Test-Path($flagfile)){
  $exitcode=2
  write-host "FAIL: $flagfile exists!"
  Get-Content -Path $flagfile | write-host
} else {
  $exitcode=0
  write-host "OK"
}

exit $exitcode
