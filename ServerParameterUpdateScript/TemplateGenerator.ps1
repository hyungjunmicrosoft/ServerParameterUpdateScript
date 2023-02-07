function Write-BasicResourcesSection{
	param (
		$OutputFileName
	)
	$temp = """resources"":`r`n
    [`r`n
        {`r`n
            ""type"": ""Microsoft.DBforPostgreSQL/flexibleServers"",`r`n
            ""apiVersion"": ""2022-01-20-preview"",`r`n
            ""name"": ""[parameters('serversName')]"",`r`n
            ""location"": ""[resourceGroup().location]"",`r`n
            ""tags"": ""[parameters('resourceTags')]"",`r`n
            ""sku"": ""[parameters('sku')]"",`r`n
            ""properties"":`r`n
            {`r`n
                ""version"": ""[parameters('serversVersion')]"",`r`n
                ""storage"": ""[parameters('storage')]"",`r`n
                ""backup"": ""[parameters('backup')]"",`r`n
                ""highAvailability"": ""[parameters('highAvailability')]"",`r`n
                ""maintenanceWindow"": ""[parameters('maintenanceWindow')]""`r`n
            }`r`n
        },`r`n"
	Add-Content $OutputFileName $temp
}

function Write-ResourcesSection{
	param (
		[array]$ServerParameters,
		$OutputFileName
	)
	Write-BasicResourcesSection -OutputFileName $OutputFileName
	$i = 0
	$str = "{`r`n
		 ""type"": ""Microsoft.DBforPostgreSQL/flexibleServers/configurations"",`r`n
		 ""apiVersion"": ""2022-01-20-preview"",`r`n
		 ""name"": ""[concat(parameters('serversName'), '/" + $ServerParameters[$i] + "')]"",`r`n
		 ""dependsOn"": [`r`n
			""[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', parameters('serversName'))]""`r`n
			],`r`n
		 ""properties"": ""[parameters('" + $ServerParameters[$i] + "')]"" `r`n
		 },`r`n"

	for($i=1; $i -lt $ServerParameters.Length; $i++)
	{
		$str = $str + "{`r`n
		 ""type"": ""Microsoft.DBforPostgreSQL/flexibleServers/configurations"",`r`n
		 ""apiVersion"": ""2022-01-20-preview"",`r`n
		 ""name"": ""[concat(parameters('serversName'), '/" + $ServerParameters[$i] + "')]"",`r`n
		 ""dependsOn"": [`r`n
			""[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', parameters('serversName'))]"",`r`n
			""[resourceId('Microsoft.DBforPostgreSQL/flexibleServers/configurations', parameters('serversName'), '" + $ServerParameters[$i-1] + "')]""`r`n
			],`r`n
		 ""properties"": ""[parameters('" + $ServerParameters[$i] + "')]"" `r`n
		 }"
		 if ($i -lt $ServerParameters.Length - 1)
		 {
			 $str = $str + ","
		 }
		 $str = $str + "`r`n"
	}
	$str = $str + "]`r`n"
	$str = $str + "}"
	Add-Content $OutputFileName $str
}


function Write-BasicParameterSection{
	param (
		$OutputFileName
	)
	$temp = "{`r`n
		""schema"": ""https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"",`r`n
		""contentVersion"": ""1.0.0.0"",`r`n"
	$temp = $temp + """parameters"":`r`n
		{`r`n"
	$temp = $temp + """serversName"":`r`n
        {`r`n
            ""type"": ""string""`r`n
        },`r`n
        ""vaultName"":`r`n
        {`r`n
            ""type"": ""string""
        },`r`n
        ""resourceTags"":`r`n
        {`r`n
            ""type"": ""object""`r`n
        },`r`n
        ""sku"":`r`n
        {`r`n
            ""type"": ""object""`r`n
        },`r`n
        ""serversVersion"":`r`n
        {`r`n
            ""type"": ""string""
        },`r`n
        ""availabilityZone"":`r`n
        {`r`n
            ""type"": ""string""`r`n
        },`r`n
        ""storage"":`r`n
        {`r`n
            ""type"": ""object""`r`n
        },`r`n
        ""backup"":`r`n
        {`r`n
            ""type"": ""object""`r`n
        },`r`n
        ""network"":`r`n
        {`r`n
            ""type"": ""object""`r`n
        },`r`n
        ""highAvailability"":`r`n
        {`r`n
            ""type"": ""object""
        },`r`n
        ""maintenanceWindow"":`r`n
        {`r`n
            ""type"": ""object""`r`n
        },`r`n
        ""adminPassword"":`r`n
        {`r`n
            ""type"": ""securestring""`r`n
        },`r`n"
	Add-Content $OutputFileName $temp
}

function Write-ParameterSection{
	param (
		[array]$ServerParameters,
		$OutputFileName
	)
	Write-BasicParameterSection -OutputFileName $OutputFileName
	$temp = ""
	for($i=0; $i -lt $ServerParameters.Length; $i++) {
		$temp = $temp + """" + $ServerParameters[$i] + """:`r`n"
		$temp = $temp + "{`r`n"
		$temp = $temp + """type"": ""object""`r`n"
		$temp = $temp + "}"
		if ($i -lt $ServerParameters.Length - 1)
		{
			$temp = $temp + ","
		}
		$temp = $temp + "`r`n"
	}
	$temp = $temp + "},`r`n"
	$temp = $temp + """variables"":`r`n
	{},"
	Add-Content $OutputFileName $temp
}

# Get the input file
Write-Host "Create ARM template to update server parameters from input parameter lists" -ForegroundColor Green
$InputFileName = Read-Host -Prompt "Input file for list of server parameter (.txt format) "
$OutputFileName = Read-Host -Prompt "Name of output file for ARM Template"
$OutputFileName = $OutputFileName + ".json"
if (Test-Path $OutputFileName) {
  Remove-Item $OutputFileName
}
# Read line
foreach($line in Get-Content $InputFileName) {
    if(-not ([string]::IsNullOrWhiteSpace($line))){
        [array]$ServerParameters += $line
    }
}
# Write ARM template
# Write Parameters Section
Write-ParameterSection -ServerParameters $ServerParameters -OutputFileName $OutputFileName
# Write Resources Section
Write-ResourcesSection -ServerParameters $ServerParameters -OutputFileName $OutputFileName

# Beautify Json 
Get-Content $OutputFileName | convertfrom-json | convertto-json -depth 100 | set-content $OutputFileName
$sRawJson = Get-Content $OutputFileName | Out-String
$sRawJson = $sRawJson -replace "\\u0027", "'"
Remove-Item $OutputFileName
$sRawJson | Out-File -FilePath $OutputFileName

Write-Host "Successfully created the ARM Template" -ForegroundColor Green

