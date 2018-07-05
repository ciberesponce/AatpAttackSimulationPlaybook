$ErrorActionPreference = "Stop"

try {
	Add-WindowsFeature RSAT-AD-AdminCenter
}
catch {
	Write-Error "Unable to add RSAT-AD-AdminCenter Feature"
	exit -1
}