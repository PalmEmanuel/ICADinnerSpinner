function Remove-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Name', ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'OfflineId', ValueFromPipeline = $true)]
        [string]$ListOfflineId
    )

    Test-IcaConnection

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        $ListOfflineId = Get-IcaShoppingList -Name $Name | Select-Object -ExpandProperty OfflineId
    }

    Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId" @script:CommonParams -Method Delete -ErrorAction Stop
}