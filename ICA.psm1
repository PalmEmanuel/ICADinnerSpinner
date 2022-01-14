$script:BaseURL = 'https://handla.api.ica.se/api'
$script:Ticket = ''

function Test-IcaTicket {
    if ([string]::IsNullOrWhiteSpace($script:Ticket)) {
        throw 'Please run Connect-IcaAPI before using this command.'
    }    
}

function Connect-IcaAPI {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )

    $BasicAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${UserName}:${Password}"))
    $AuthResponse = Invoke-WebRequest -Headers @{ 'Authorization' = "Basic $BasicAuth" } -Uri "$BaseURL/login"
    $script:Ticket = $AuthResponse.Headers.AuthenticationTicket[0]
}

function Get-IcaUserCardInfo {    
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }
    Invoke-RestMethod "$BaseUrl/user/cardaccounts" -Headers $Headers
}

function Get-IcaUserBonusInfo {    
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }
    Invoke-RestMethod "$BaseUrl/user/minbonustransaction" -Headers $Headers
}

function Get-IcaStore {
    param (
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [int]$Id,

        [Parameter(Mandatory, ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory, ParameterSetName = 'SyncTime')]
        [ValidateNotNullOrEmpty()]
        [datetime]$LastSyncTime,
        
        [Parameter(Mandatory, ParameterSetName = 'User')]
        [ValidateNotNullOrEmpty()]
        [switch]$FromUser
    )
    
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            Invoke-RestMethod "$BaseUrl/stores/$Id" -Headers $Headers
        }
        'String' {
            Invoke-RestMethod "$BaseUrl/stores/search?Filters&Phrase=$SearchString" -Headers $Headers
        }
        'SyncTime' {
            Invoke-RestMethod "$BaseUrl/stores/?LastSyncDate=$($LastSyncTime.ToString('yyyy-MM-dd'))" -Headers $Headers
        }
        'User' {
            Invoke-RestMethod "$BaseUrl/user/stores" -Headers $Headers
        }
    }
}

function Get-IcaStoreOffers {
    param (
        [Parameter(Mandatory)]
        [string[]]$StoreId
    )
    
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }
    
    Invoke-RestMethod "$BaseUrl/offers?Stores=$($StoreId -join ',')" -Headers $Headers
}

function Get-IcaShoppingList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'OfflineId')]
        [string]$OfflineId,
        
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    # Get all if offline id not specified
    if ($PSCmdlet.ParameterSetName -ne 'OfflineId') {
        $Lists = Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists" -Headers $Headers | Select-Object -ExpandProperty ShoppingLists
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
        Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$OfflineId" -Headers $Headers
    }
}

function New-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [int64]$StoreId = 0
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    $OfflineId = (New-Guid).Guid

    $Body = @{
        'Title'        = $Name
        'OfflineId'    = $OfflineId
        'SortingStore' = $StoreId
    }

    $null = Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists" -Headers $Headers -Method Post -Body $Body
    return $OfflineId
}

function Remove-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'OfflineId')]
        [string]$OfflineId
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        $OfflineId = Get-IcaShoppingList -Name $Name | Select-Object -ExpandProperty OfflineId
    }

    Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$OfflineId" -Headers $Headers -Method Delete
}

function Add-IcaShoppingListItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$OfflineId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Product
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    $Body = @{
        'CreatedRows' = @($Product | ForEach-Object {
                @{
                    'ProductName'   = $_
                    'IsStrikedOver' = $false
                }
            })
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$OfflineId/sync" -Headers $Headers -Method Post -Body $Body -ContentType 'application/json; charset=utf-8'
}

function Get-IcaUserCommonProducts {
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    Invoke-RestMethod "$BaseUrl/user/commonarticles" -Headers $Headers
}

function Get-IcaProductGroups {
    [CmdletBinding()]
    param (
        [datetime]$LastSyncTime = (Get-Date '2001-01-01')
    )
    
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    $LastSyncTimeString = $LastSyncTime.ToString('yyyy-MM-dd')

    Invoke-RestMethod "$BaseUrl/articles/articlegroups?lastsyncdate=$LastSyncTimeString" -Headers $Headers | Select-Object -ExpandProperty ArticleGroups
}

function Get-IcaProduct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int64[]]$UPCCode
    )
    
    Test-IcaTicket

    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    Invoke-RestMethod "$BaseUrl/upclookup?upc=$($UPCCode -join ',')" -Headers $Headers
}

function Get-IcaRecipe {
    param (
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [int]$Id,

        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [switch]$ExcludeRating,

        [Parameter(Mandatory, ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory, ParameterSetName = 'Random')]
        [ValidateNotNullOrEmpty()]
        [switch]$Random,

        [Parameter(ParameterSetName = 'Random')]
        [ValidateNotNullOrEmpty()]
        [int]$NumberOfRecipes = 5,

        [Parameter(Mandatory, ParameterSetName = 'User')]
        [switch]$SavedByUser
    )
    
    Test-IcaTicket

    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    # Needs [System.Net.WebUtility]::HtmlDecode for the CookingSteps property (and maybe others)

    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            $Recipe = Invoke-RestMethod "$BaseUrl/recipes/recipe/$Id" -Headers $Headers
            if (-not $ExcludeRating.IsPresent) {
                
            }
        }
        'String' {
            Invoke-RestMethod "$BaseUrl/recipes/searchwithfilters?phrase=$SearchString&recordsPerPage=10000&pageNumber=0&sorting=0" -Headers $Headers
        }
        'User' {
            Invoke-RestMethod "$BaseUrl/user/recipes" -Headers $Headers
        }
        'Random' {
            Invoke-RestMethod "$BaseUrl/recipes/random?numberOfRecipes=$NumberOfRecipes" -Headers $Headers | Select-Object -ExpandProperty Recipes
        }
    }
}

function Get-IcaRecipeFilters {    
    Test-IcaTicket

    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }
    
    Invoke-RestMethod "$BaseUrl/recipes/search/filters" -Headers $Headers
}

function Get-IcaRecipeCategories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Id')]
        [int]$Id,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$all
    )

    Test-IcaTicket

    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            $Properties = @(
                'ImageId'
                'Title'
                'CookingTime'
                'AverageRating'
                'OfferCount'
                'IngredientCount'
            ) -join ','
            Invoke-RestMethod "$BaseUrl/recipes/categories/general/$Id?recordsPerPage=10000&pageNumber=0&include=$Properties" -Headers $Headers
        }
        'All' {
            Invoke-RestMethod "$BaseUrl/recipes/categories/general" -Headers $Headers
        }
    }
}

function New-IcaRandomRecipeList {
    $Recipe = Get-IcaRecipe -Random -NumberOfRecipes 1
    $Ingredients = $Recipe.IngredientGroups | ForEach-Object {
        $_.Ingredients | ForEach-Object {
            $_.Ingredient
        }
    }
    
    $ListId = New-IcaShoppingList -Name "Recept - $($Recipe.Title)"
    Add-IcaShoppingListItem -OfflineId $ListId -Product $Ingredients
}