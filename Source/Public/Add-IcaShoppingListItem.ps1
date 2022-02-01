function Add-IcaShoppingListItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$ListOfflineId,

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ProductName
    )

    Test-IcaTicket

    $Body = @{
        'CreatedRows' = @(
            $ProductName | ForEach-Object {
                @{
                    'ProductName'   = $_
                    'IsStrikedOver' = $false
                }
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body
}