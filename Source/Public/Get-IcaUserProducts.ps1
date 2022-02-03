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

    Test-IcaConnection

    switch ($PSCmdlet.ParameterSetName) {
        'Common' {
            Invoke-RestMethod "$script:BaseURL/user/commonarticles" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty CommonArticles
        }
        'Base' {
            Invoke-RestMethod "$script:BaseURL/user/baseitems" @script:CommonParams -ErrorAction Stop
        }
        'MostPurchased' {
            Invoke-RestMethod "$script:BaseURL/user/getMostPurchasedItems" @script:CommonParams -ErrorAction Stop
        }
    }
}