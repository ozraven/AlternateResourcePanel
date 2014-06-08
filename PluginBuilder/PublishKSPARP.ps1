$GitHubName="AlternateResourcePanel"
$PluginName="KSPAlternateResourcePanel"
$UploadDir = "..\_Uploads\KSPAlternateResourcePanel"

$Version = Read-Host -Prompt "Enter the Version Number to Publish" 


if ($Version -eq "")
{
    "No version string supplied... Quitting"
    return
}
else
{
    if (Test-Path "$UploadDir\v$($Version)\$($PluginName)_$($Version)\GameData\TriggerTech\$($PluginName)\$($PluginName).dll")
    {
	    $dll = get-item "$UploadDir\v$($Version)\$($PluginName)_$($Version)\GameData\TriggerTech\$($PluginName)\$($PluginName).dll"
	    $VersionString = $dll.VersionInfo.ProductVersion

        if ($Version -ne $VersionString) {
            "Versions dont match`r`nEntered:`t$Version`r`nFrom File:`t$VersionString"
            return
        } else {
            $OAuthToken = Read-Host -Prompt "OAuth Token"
        }
    } else {
        "Cant find the dll - have you built the dll first?"
        return
    }
}


    

"`r`nThis will Merge the devbranch with master and push the release of v$($Version) of the $($PluginName)"
"`tFrom:`t$UploadDir\v$($Version)"
"`tOAauth:`t$OAuthToken"
$Choices= [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes","&No")
$ChoiceRtn = $host.ui.PromptForChoice("Do you wish to Continue?","Be sure dveelop is ready before hitting yes",$Choices,1)

if($ChoiceRtn -eq 0)
{
	#git add -A *
	#git commit -m "Version history $($Version)"
	
	#write-host -ForegroundColor Yellow "`r`nPUSHING DEVELOP TO GITHUB"
	#git push

    write-host -ForegroundColor Yellow "`r`nMERGING DVEELOP TO MASTER"

	git checkout master
	git merge --no-ff develop -m "Merge $($Version) to master"
	git tag -a "v$($Version)" -m "Released version $($Version)"

	write-host -ForegroundColor Yellow "`r`nPUSHING MASTER AND TAGS TO GITHUB"
	git push
	git push --tags
	
	write-host -ForegroundColor Yellow "----------------------------"
	write-host -ForegroundColor Yellow "Finished Version $($Version)"
	write-host -ForegroundColor Yellow "----------------------------"
	
	write-host -ForegroundColor Yellow "`r`n Creating Release"
	$readme = (Get-Content -Raw "PluginFiles\ReadMe-$($PluginName).txt")
	$reldescr = [regex]::match($readme,"Version\s$($Version).+?(?=[\r\n]*Version\s\d+|$)","singleline,ignorecase").Value

	#Now get the KSPVersion from the first line
	$KSPVersion = [regex]::match($reldescr,"KSP\sVersion\:.+?(?=[\r\n]|$)","singleline,ignorecase").Value
	
	#Now drop the first line
	$reldescr = [regex]::replace($reldescr,"^.+?\r\n","","singleline,ignorecase")
	
	$reldescr = $reldescr.Trim("`r`n")
	$reldescr = $reldescr.Replace("- ","* ")
	$reldescr = $reldescr.Replace("`r`n","\r\n")
	$reldescr = $reldescr.Replace("`"","\`"")
	
	$reldescr = "$($reldescr)\r\n\r\n``````$($KSPVersion)``````"

	$CreateBody = "{`"tag_name`":`"v$($Version)`",`"name`":`"v$($Version) Release`",`"body`":`"$($relDescr)`"}"
	
	$RestResult = Invoke-RestMethod -Method Post `
		-Uri "https://api.github.com/repos/TriggerAu/$($GitHubName)/releases" `
		-Headers @{"Accept"="application/vnd.github.v3+json";"Authorization"="token " + $OAuthToken} `
		-Body $CreateBody
	if ($?)
	{
		write-host -ForegroundColor Yellow "Uploading File"
		$File = get-item "$($UploadDir)\v$($Version)\$($pluginname)_$($Version).zip"
		$RestResult = Invoke-RestMethod -Method Post `
			-Uri "https://uploads.github.com/repos/TriggerAu/$($GitHubName)/releases/$($RestResult.id)/assets?name=$($File.Name)" `
			-Headers @{"Accept"="application/vnd.github.v3+json";"Authorization"="token 585a29de3d6a38a3cb777f49335e8024572a23dc";"Content-Type"="application/zip"} `
			-InFile $File.fullname
		
		"Result = $($RestResult.state)"
	}

	write-host -ForegroundColor Yellow "----------------------------"
	write-host -ForegroundColor Yellow "Finished Release $($Version)"
	write-host -ForegroundColor Yellow "----------------------------"
}
else
{
    "Skipping..."
}