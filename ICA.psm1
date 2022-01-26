$script:BaseURL = 'https://handla.api.ica.se/api'
$script:Ticket = ''

$PSDefaultParameterValues = @{
    'Invoke-RestMethod:ContentType' = 'application/json; charset=utf-8'
}

class IcaFilter : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-IcaRecipeFilters).Options.Id | Sort-Object -Unique
    }
}

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
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipeline = $true)]
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

        [Parameter(Mandatory, ParameterSetName = 'OfflineId', ValueFromPipeline = $true)]
        [string]$OfflineId,
        
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'OfflineId')]
        [switch]$CommonProducts,
        
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
        $Url = "$BaseUrl/user/offlineshoppinglists/$OfflineId"

        if ($CommonProducts.IsPresent) {
            Invoke-RestMethod "$Url/common" -Headers $Headers | Select-Object -ExpandProperty CommonProducts
        }
        else {
            Invoke-RestMethod $Url -Headers $Headers
        }
    }
}

function New-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
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
        'Rows'         = @()
        'LatestChange' = Get-Date -Format 'yyyy-MM-ddThh:mm:ssZ'
    }

    $null = Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists" -Headers $Headers -Method Post -Body $Body
    return $OfflineId
}

function Remove-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Name', ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'OfflineId', ValueFromPipeline = $true)]
        [string]$ListOfflineId
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        $ListOfflineId = Get-IcaShoppingList -Name $Name | Select-Object -ExpandProperty OfflineId
    }

    Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$ListOfflineId" -Headers $Headers -Method Delete
}

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
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

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

    Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$ListOfflineId/sync" -Headers $Headers -Method Post -Body $Body
}

function Remove-IcaShoppingListItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$ListOfflineId,

        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ProductOfflineId
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    $Body = [ordered]@{
        'ChangedShoppingListProperties' = @{
        }
        'CreatedRows'                   = @()
        'ChangedRows'                   = @()
        'DeletedRows'                   = $ProductOfflineId
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$ListOfflineId/sync" -Headers $Headers -Method Post -Body $Body
}

# Get input list, make a diff check and compose a body with created, changed and deleted rows
# function Set-IcaShoppingList {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory, ValueFromPipeline = $true)]
#         [string]$ListOfflineId,

#         [Parameter(ValueFromPipeline = $true)]
#         [string]$Name
#     )

#     Test-IcaTicket
    
#     $Headers = @{
#         'AuthenticationTicket' = $Ticket
#     }

#     $Body = @{
#         'ChangedShoppingListProperties' = @{
#             'Title'        = $Name
#             'LatestChange' = Get-Date -Format 'yyyy-MM-ddThh:mm:ssZ'
#         }
#         'CreatedRows'                   = @()
#         'ChangedRows'                   = @()
#         'DeletedRows'                   = @()
#     } | ConvertTo-Json -Depth 10 -Compress

#     Invoke-RestMethod "$BaseUrl/user/offlineshoppinglists/$ListOfflineId/sync" -Headers $Headers -Method Post -Body $Body
# }

function Get-IcaUserProducts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Common')]
        [switch]$CommonProducts,

        [Parameter(Mandatory, ParameterSetName = 'Base')]
        [switch]$BaseItems
    )

    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Common' {
            Invoke-RestMethod "$BaseUrl/user/commonarticles" -Headers $Headers
        }
        'Base' {
            Invoke-RestMethod "$BaseUrl/user/baseitems" -Headers $Headers
        }
    }
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
        [Parameter(Mandatory, ValueFromPipeline = $true)]
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
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$Id,

        [Parameter(Mandatory, ParameterSetName = 'String')]
        [AllowEmptyString()]
        [string]$SearchString,

        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [ValidateSet([IcaFilter])]
        [string[]]$Filter,

        [Parameter(ParameterSetName = 'String')]
        [Parameter(ParameterSetName = 'Filter')]
        [int]$StoreId = 0,

        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'String')]
        [int]$NumberOfRecipes = 1,

        [Parameter(Mandatory, ParameterSetName = 'Category')]
        [int]$CategoryId,

        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'Random')]
        [Parameter(ParameterSetName = 'String')]
        [switch]$Full,

        [Parameter(ParameterSetName = 'Random')]
        [switch]$Random,

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
            $Recipes = $Id | ForEach-Object { Invoke-RestMethod "$BaseUrl/recipes/recipe/$_" -Headers $Headers }
        }
        'String' {
            $Page = 0
            do {
                $Result = Invoke-RestMethod "$BaseUrl/recipes/searchwithfilters?phrase=$SearchString&recordsPerPage=1000&pageNumber=$Page&sorting=$StoreId" -Headers $Headers
                $Page++
                $Recipes += $Result.Recipes
            } while ($Page -le $Result.NumberOfPages -and $Recipes.Count -lt $NumberOfRecipes)
            $Recipes = $Recipes | Sort-Object { Get-Random } | Select-Object -First $NumberOfRecipes
        }
        'Filter' {
            $Page = 0
            do {
                $Result = Invoke-RestMethod "$BaseUrl/recipes/searchwithfilters?phrase=&recordsPerPage=1000&pageNumber=$Page&filters=$($Filter -join ',')&sorting=$StoreId" -Headers $Headers
                $Page++
                $Recipes += $Result.Recipes
            } while ($Page -le $Result.NumberOfPages -and $Recipes.Count -lt $NumberOfRecipes)
            $Recipes = $Recipes | Sort-Object { Get-Random } | Select-Object -First $NumberOfRecipes
        }
        'User' {
            $Recipes = Invoke-RestMethod "$BaseUrl/user/recipes" -Headers $Headers | Select-Object -ExpandProperty UserRecipes | ForEach-Object {
                Get-IcaRecipe -Id $_.RecipeId
            }
            $NumberOfRecipes = $Recipes.Count
        }
        'Random' {
            if ($CategoryId -ge 0) {
                $Recipes = Invoke-RestMethod "$BaseUrl/recipes/categories/general/${CategoryId}?recordsPerPage=1000&pageNumber=0" -Headers $Headers | 
                Select-Object -ExpandProperty Recipes |
                Sort-Object { Get-Random }
            }
            elseif ($Random.IsPresent) {
                Write-Warning @'
The endpoint used for random recipes is limited to only around 50 recipes at a time with a fairly sparse selection of recipes.
For a larger selection to randomize from, send an empty string using the -SearchString parameter combined with -NumberOfRecipes.
'@
                $Recipes = Invoke-RestMethod "$BaseUrl/recipes/random?numberOfRecipes=$NumberOfRecipes" -Headers $Headers | Select-Object -ExpandProperty Recipes
            }
            else {
                throw 'Parameter combination not supported!'
            }
        }
    }

    if ($Full.IsPresent) {
        Write-Warning "The Full parameter means that one extra request to the ICA API will be made for each recipe found, up to $NumberOfRecipes (NumberOfRecipes). This can take a while."
        $Recipes = $Recipes | ForEach-Object { Get-IcaRecipe -Id $_.Id }
    }

    Write-Output $Recipes | Sort-Object { Get-Random } | Select-Object -First $NumberOfRecipes
}

function Get-IcaRecipeFilters {    
    Test-IcaTicket

    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }
    
    Invoke-RestMethod "$BaseUrl/recipes/search/filters" -Headers $Headers | Select-Object -ExpandProperty categories
}

function Get-IcaRecipeCategories {
    Test-IcaTicket

    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    # Invoke-RestMethod "$BaseUrl/recipes/categories/general" -Headers $Headers | Select-Object -ExpandProperty Categories
    Invoke-RestMethod "$BaseUrl/recipes/categories/puff?includeWeeklyMixCategory=true" -Headers $Headers | Select-Object -ExpandProperty Categories
}

function New-IcaRandomRecipeList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$CategoryId
    )

    $Recipe = Get-IcaRecipe -Random -NumberOfRecipes 1 -CategoryId $CategoryId
    $Ingredients = $Recipe.IngredientGroups | ForEach-Object {
        $_.Ingredients | ForEach-Object {
            $_.Ingredient
        }
    }
    
    $ListId = New-IcaShoppingList -Name "Recept - $($Recipe.Title)"
    Add-IcaShoppingListItem -OfflineId $ListId -Product $Ingredients
}

function Get-IcaCurrentInfo {
    Test-IcaTicket
    
    $Headers = @{
        'AuthenticationTicket' = $Ticket
    }

    Invoke-RestMethod "$BaseUrl/info/urgent" -Headers $Headers
}