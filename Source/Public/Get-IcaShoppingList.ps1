function Get-IcaShoppingList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'OfflineId', ValueFromPipeline = $true)]
        [string]$OfflineId,
        
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'OfflineId')]
        [switch]$CommonProducts,
        
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    Test-IcaTicket

    # Get all if offline id not specified
    if ($PSCmdlet.ParameterSetName -ne 'OfflineId') {
        $Lists = Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists" @script:CommonParams | Select-Object -ExpandProperty ShoppingLists
    }

    # Return all
    if ($PSCmdlet.ParameterSetName -eq 'All') {
        $Lists
    } # Or get by id
    else {
        # If id is specified, get offline id from the list of all shopping lists
        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $OfflineId = $Lists | Where-Object { $_.Title -eq $Name } | Select-Object -ExpandProperty OfflineId

            if ($null -eq $OfflineId) {
                throw "Could not find shopping list with the name $Name!"
            }
            elseif ($OfflineId.Count -gt 1) {
                throw "Found multiple shopping lists with the name $Name!"
            }
        }
        
        # Get list details by offline id
        $Url = "$script:BaseURL/user/offlineshoppinglists/$OfflineId"

        if ($CommonProducts.IsPresent) {
            Invoke-RestMethod "$Url/common" @script:CommonParams | Select-Object -ExpandProperty CommonProducts
        }
        else {
            Invoke-RestMethod $Url @script:CommonParams
        }
    }
}