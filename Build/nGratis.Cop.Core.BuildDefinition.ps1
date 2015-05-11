properties {	
	$Version = "$MajorVersion.$MinorVersion.$BuildVersion.$RevisionVersion"

	$BuildFolderPath = "$($RootFolderPath)Build\"
	$SourceFolderPath = "$($RootFolderPath)Source\"
	$ToolsFolderPath = "$($RootFolderPath)Tools\"
	$OutputFolderPath = "$($RootFolderPath)Output\"
	
	$InputBinariesFolderPath = "$($SourceFolderPath)nGratis.Cop.Theia.Binaries\$Configuration\"
	$OutputBinariesFolderPath = "$($OutputFolderPath)Bin\"
	$InputNugetFolderPath = "$($BuildFolderPath)NuGet\"
	$OutputNugetFolderPath = "$($OutputFolderPath)NuGet\"
	
	$MsbuildLogFilePath = "$($OutputFolderPath)nGratis.Cop.Theia.MSBUILD.log"
	
	$T4ExePath = [System.Environment]::ExpandEnvironmentVariables("%CommonProgramFiles(x86)%\Microsoft Shared\TextTemplating\12.0\TextTransform.exe")
	$NugetExePath = "$($ToolsFolderPath)NuGet\NuGet.exe"
}

Task default -Depends Finalize

Task Initialize {
	Write-Host "1> Configuration: '$Configuration' "
	Write-Host "1> Platform: '$Platform' "
	Write-Host "1> Version: '$Version'"
	Write-Host "1> Build Timestamp: '$BuildTimestamp'"
	
	Write-Host "1> Root Folder: '$RootFolderPath' "
	Write-Host "1> Build Folder: '$BuildFolderPath' "
	Write-Host "1> Source Folder: '$SourceFolderPath' "
	Write-Host "1> Tools Folder: '$ToolsFolderPath' "
	Write-Host "1> Output Folder: '$OutputFolderPath' "
}

Task Clean -Depends Initialize { 
	if (Test-Path -Path $OutputFolderPath)
	{
		Write-Host "2> Deleting 'Output' folder"
		Remove-Item -Path $OutputFolderPath -Recurse -Force
	}
	
	$IsInitialized = $true
	
	if (-not (Test-Path -Path $T4ExePath))
	{
		Write-Error "2> T4 executable file '$T4ExePath' is not found"
		$IsInitialized = $false
	}
	
	if (-not (Test-Path -Path $NugetExePath))
	{
		Write-Error "2> NuGet executable file '$NugetExePath' is not found"
		$IsInitialized = $false
	}
	
	if (-not $IsInitialized)
	{
		throw "Task 'Initialize' failed to complete!"
	}
}

Task Compile -Depends Clean {
	if (-not(Test-Path -Path $MsbuildLogFilePath))
	{
		Write-Host "3> Creating MSBUILD log file '$MsbuildLogFilePath'"
		New-Item -Path $MsbuildLogFilePath -ItemType file -Force | Out-Null
	}
	
	$AssemblyInfoFilePath = "$($SourceFolderPath)nGratis.Cop.Theia.Common\GlobalAssemblyInfo.tt"
	Write-Host "3> Transforming global assembly info file '$AssemblyInfoFilePath'"
	& $T4ExePath $AssemblyInfoFilePath -a !!Version!"$Version" -a !!BuildTimestamp!"$BuildTimestamp"
	
	$SolutionFilePath = "$($SourceFolderPath)nGratis.Cop.Theia.sln"
	$TargetParameter = "/t:""Clean,Rebuild"""
	$PropertyParameter = "/p:Configuration=""$Configuration"" /p:Platform=""$Platform"""
	$LogParameter = "/noconlog /fl /flp:LogFile=""$MsbuildLogFilePath"""
	
	Write-Host "3> Building solution file '$SolutionFilePath'"
	Invoke-Expression -Command "MsBuild.exe $SolutionFilePath /nologo $TargetParameter $PropertyParameter $LogParameter" | Out-Null
	
	if ($LastExitCode)
	{
		Write-Error "3> Failed to build solution file '$SolutionFilePath' with error code '$ErrorCode'"
		throw "Task 'Compile' failed to complete!"
	}
	
	Write-Host "3> Copying binaries to folder '$OutputBinariesFolderPath'"
	Copy-Item -Path $InputBinariesFolderPath -Destination $OutputBinariesFolderPath -Recurse -Force

	Write-Host "3> Copying core testing binary to folder'$OutputBinariesFolderPath'"
	Get-ChildItem -Path "$($SourceFolderPath)nGratis.Cop.Core.Testing\bin\$Configuration\" -Filter "*.Testing.*" |
	ForEach-Object { Copy-Item -Path $_.FullName -Destination $OutputBinariesFolderPath -Force }
}

Task Package -Depends Compile {	
	if (-not(Test-Path -Path $OutputNugetFolderPath))
	{
		Write-Host "3> Creating output NUGET folder '$OutputNugetFolderPath'"
		New-Item -Path $OutputNugetFolderPath -ItemType directory -Force | Out-Null
	}

	Write-Host "4> Transforming NuGet specification files"
	Get-ChildItem -Path $InputNugetFolderPath -Filter "*.tt" -Recurse |
	ForEach-Object -Process { & $T4ExePath $_.FullName -a !!Version!"$Version" -a !!BuildTimestamp!"$BuildTimestamp" }
	
	Write-Host "4> Packing NuGet specification files"
	Get-ChildItem -Path $InputNugetFolderPath -Filter "*.nuspec" -Recurse |
	ForEach-Object -Process {
		& $NugetExePath pack $_.FullName -BasePath "$OutputBinariesFolderPath" -OutputDirectory "$OutputNugetFolderPath" -NonInteractive | Out-Null
		Write-Host "   |_ Packing specification file '$_'"
	}	
}

Task Finalize -Depends Package {
	Write-Host "5> Cooling down build definition file"
}