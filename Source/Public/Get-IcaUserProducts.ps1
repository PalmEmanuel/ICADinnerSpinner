function Get-IcaUserProducts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Common')]
        [switch]$CommonProducts,

        [Parameter(Mandatory, ParameterSetName = 'Base')]
        [switch]$BaseItems,

        [Parameter(Mandatory, ParameterSetName = 'MostPurchased')]
        [switch]$MostPurchased
    )

    Test-IcaTicket

    switch ($PSCmdlet.ParameterSetName) {
        'Common' {
            Invoke-RestMethod "$script:BaseURL/user/commonarticles" @script:CommonParams
        }
        'Base' {
            Invoke-RestMethod "$script:BaseURL/user/baseitems" @script:CommonParams
        }
        'MostPurchased' {
            Invoke-RestMethod "$script:BaseURL/user/getMostPurchasedItems" @script:CommonParams
        }
    }
}