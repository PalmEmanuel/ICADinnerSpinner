# Common parameters for all API requests in the module
# The authentication ticket gets added to this splat hash by Connect-IcaAPI
$script:CommonParams = @{
	'ContentType' = 'application/json; charset=utf-8'
}
$script:BaseURL = 'https://handla.api.ica.se/api'

# Import classes
foreach ($File in (Get-ChildItem "$PSScriptRoot\Classes\*.ps1"))
{
	try {
		Write-Verbose "Importing $($File.FullName)"
		. $File.FullName
	}
	catch {
		Write-Error "Failed to import '$($File.FullName)'. $_"
	}
}

# Import private functions
foreach ($File in (Get-ChildItem "$PSScriptRoot\Private\*.ps1"))
{
	try {
		Write-Verbose "Importing $($File.FullName)"
		. $File.FullName
	}
	catch {
		Write-Error "Failed to import '$($File.FullName)'. $_"
	}
}

# Import public functions
foreach ($File in (Get-ChildItem "$PSScriptRoot\Public\*.ps1"))
{
	try {
		Write-Verbose "Importing $($File.FullName)"
		. $File.FullName
	}
	catch {
		Write-Error "Failed to import '$($File.FullName)'. $_"
	}
}