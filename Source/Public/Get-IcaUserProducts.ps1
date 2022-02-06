function Get-IcaUserProducts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Common','Base','MostPurchased','SmartReminders')]
        [string]$Type
    )

    Test-IcaConnection

    switch ($Type) {
        'Common' {
            Invoke-RestMethod "$script:BaseURL/user/commonarticles" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty CommonArticles
        }
        'Base' {
            Invoke-RestMethod "$script:BaseURL/user/baseitems" @script:CommonParams -ErrorAction Stop
        }
        'MostPurchased' {
            Invoke-RestMethod "$script:BaseURL/user/getMostPurchasedItems" @script:CommonParams -ErrorAction Stop
        }
        'SmartReminders' {
            Invoke-RestMethod "$script:BaseURL/user/smartreminders" @script:CommonParams -ErrorAction Stop
        }
    }
}