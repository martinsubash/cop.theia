properties {	
	$Version = "$MajorVersion.$MinorVersion.$BuildVersion.$RevisionVersion"

	$BuildFolderPath = "$($RootFolderPath)Build\"
	$SourceFolderPath = "$($RootFolderPath)Source\"
	$ToolsFolderPath = "$($RootFolderPath)Tools\"
	$OutputFolderPath = "$($RootFolderPath)Output\"
	$ArchiveFolderPath = "$($RootFolderPath)Archive\"
	
	$InputBinariesFolderPath = "$($SourceFolderPath)nGratis.Cop.Theia.Binaries\$Configuration\"
	$OutputBinariesFolderPath = "$($OutputFolderPath)Bin\"
	$InputNugetFolderPath = "$($BuildFolderPath)NuGet\"
	$OutputNugetFolderPath = "$($OutputFolderPath)NuGet\"
	
	$MsbuildLogFilePath = "$($OutputFolderPath)nGratis.Cop.Theia.MSBUILD.log"
	
	$T4ExePath = [System.Environment]::ExpandEnvironmentVariables("%CommonProgramFiles(x86)%\Microsoft Shared\TextTemplating\14.0\TextTransform.exe")
	$NugetExePath = "$($ToolsFolderPath)NuGet\nuget.exe"
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
	Write-Host "1> Archive Folder: '$ArchiveFolderPath' "
}

Task Clean -Depends Initialize { 
	if (-not(Test-Path -Path $ArchiveFolderPath))
	{
		Write-Host "2> Creating archive folder '$ArchiveFolderPath'"
		New-Item -Path $ArchiveFolderPath -ItemType "Directory" -Force | Out-Null
	}

	if (Test-Path -Path $OutputNugetFolderPath)
	{
		Write-Host "2> Archiving existing NuGet packages"
		Get-ChildItem -Path $OutputNugetFolderPath -Filter "*.nupkg" -Recurse |
		ForEach-Object -Process {
			Copy-Item -Path $_.FullName -Destination $ArchiveFolderPath -Force
			Write-Host "   |_ $($_.Name)"
		}
	}

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
	$TargetParameter = "/target:Clean;Rebuild"
	$PropertyParameter = "/property:Configuration=""$Configuration"";Platform=""$Platform"""
	$LogParameter = "/nologo /noconlog /verbosity:Detailed /fl /flp:LogFile=""$MsbuildLogFilePath"""
	
	Write-Host "3> Building solution file '$SolutionFilePath'"
	$BuildResult = Invoke-MsBuild -Path $SolutionFilePath -Params "$TargetParameter $PropertyParameter $LogParameter"
	
	if ($BuildResult.BuildSucceeded -eq $false)
	{
		Write-Error "3> Failed to build solution file '$SolutionFilePath' with error '$BuildResult.Message'"
		throw "Task 'Compile' failed to complete!"
	}
	
	Write-Host "3> Copying binaries to folder '$OutputBinariesFolderPath'"
	Copy-Item -Path $InputBinariesFolderPath -Destination $OutputBinariesFolderPath -Recurse -Force

	Write-Host "3> Copying core testing binary to folder'$OutputBinariesFolderPath'"
	Get-ChildItem -Path "$($SourceFolderPath)nGratis.Cop.Core.Testing\bin\$Configuration\" -Filter "*.Testing.*" |
	ForEach-Object -Process { Copy-Item -Path $_.FullName -Destination $OutputBinariesFolderPath -Force }
}

Task Package -Depends Compile {
	if (-not(Test-Path -Path $OutputNugetFolderPath))
	{
		Write-Host "3> Creating output NUGET folder '$OutputNugetFolderPath'"
		New-Item -Path $OutputNugetFolderPath -ItemType "Directory" -Force | Out-Null
	}

	Write-Host "4> Transforming NuGet specification files"
	Get-ChildItem -Path $InputNugetFolderPath -Filter "*.tt" -Recurse |
	ForEach-Object -Process { & $T4ExePath $_.FullName -a !!Version!"$Version" -a !!BuildTimestamp!"$BuildTimestamp" }
	
	Write-Host "4> Packing NuGet specification files"
	Get-ChildItem -Path $InputNugetFolderPath -Filter "*.nuspec" -Recurse |
	ForEach-Object -Process {
		& $NugetExePath pack $_.FullName -BasePath "$OutputBinariesFolderPath" -OutputDirectory "$OutputNugetFolderPath" -NonInteractive | Out-Null
		Write-Host "   |_ $($_.Name)"
	}	
}

Task Finalize -Depends Package {
	Write-Host "5> Cooling down build definition file"
}