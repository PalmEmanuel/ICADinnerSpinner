function Remove-IcaShoppingListItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$ListOfflineId,

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ProductOfflineId
    )

    Test-IcaConnection

    $Body = [ordered]@{
        'ChangedShoppingListProperties' = @{
        }
        'CreatedRows'                   = @()
        'ChangedRows'                   = @()
        'DeletedRows'                   = @($ProductOfflineId)
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
}