function Remove-IcaStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$StoreId
    )
    
    Test-IcaConnection

    Invoke-RestMethod "$script:BaseURL/user/stores?id=$StoreId" @script:CommonParams -Method Delete -ErrorAction Stop
}