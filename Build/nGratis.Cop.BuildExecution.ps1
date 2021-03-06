param(
)

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"

Clear-Host
Write-Host "0> ----- Build execution started -----" -ForegroundColor Yellow

$RootFolderPath = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..\"
Write-Host "0> Setting root folder path to '$($RootFolderPath)'"

Write-Host "0> Importing external modules"
Import-Module "$($RootFolderPath)Tools\psake\psake.psm1"
Import-Module "$($RootFolderPath)Tools\Invoke-MsBuild\Invoke-MsBuild.psm1"

try
{
	$DefinitionFilePath = "$($RootFolderPath)Build\nGratis.Cop.Core.BuildDefinition.ps1"

	Write-Host "0> Firing up build definition file '$DefinitionFilePath'"
	
	$BuildTimestamp = [System.DateTimeOffset]::UtcNow;
	$EpochTimestamp = [System.DateTimeOffset]::Parse(
		"01/01/2015 00:00:00AM +00:00", 
		[System.Globalization.CultureInfo]::InvariantCulture,
		[System.Globalization.DateTimeStyles]::AdjustToUniversal)
	
	$BuildVersion = (($BuildTimestamp - $EpochTimestamp).TotalDays -as [int]).ToString([System.Globalization.CultureInfo]::InvariantCulture)
	$RevisionVersion = $BuildTimestamp.ToString("HHmm", [System.Globalization.CultureInfo]::InvariantCulture)
		
	$Parameters = @{
		"RootFolderPath" = $RootFolderPath
		"Configuration" = "Release"
		"Platform" = "Any CPU"
		"MajorVersion" = "0"
		"MinorVersion" = "1"
		"BuildVersion" = $BuildVersion
		"RevisionVersion" = $RevisionVersion
		"BuildTimestamp" = $BuildTimestamp.ToString("O", [System.Globalization.CultureInfo]::InvariantCulture)
	}
	
	Invoke-psake $DefinitionFilePath -Properties @{} -Parameters $Parameters | Out-Null
}
finally 
{
	Write-Host "0> Unloading external modules"
	Remove-Module "psake"
	Remove-Module "Invoke-MsBuild"
}

Write-Host "0> ----- Build execution ended -----" -ForegroundColor Green
Write-Host

Read-Host "Press [ENTER] to continue"