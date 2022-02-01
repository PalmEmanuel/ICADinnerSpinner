$script:BaseURL = 'https://handla.api.ica.se/api'

# Common parameters for all API requests in the module
# The authentication ticket gets added to this splat hash by Connect-IcaAPI
$script:CommonParams = @{
    'ContentType' = 'application/json; charset=utf-8'
}

# Define a ValidateSetGenerator that gets the recipe categories
class IcaFilter : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-IcaRecipeFilters).Options.Id | Select-Object -Unique
    }
}

class IcaProductRecipeReference {
    [int]$Id # Id of the recipe
    
    [double]$Quantity
    
    [ValidateNotNullOrEmpty()]
    [string]$Unit

    IcaProductRecipeReference(
        [int]$Id, 
        [double]$Quantity,
        [string]$Unit
    ) {
        $this.Id = $Id
        $this.Quantity = $Quantity
        $this.Unit = $Unit
    }
}

class IcaProduct {
    [int]$InternalOrder # -1..-$Count

    [ValidateNotNullOrEmpty()]
    [string]$ProductName

    [bool]$IsStrikedOver

    [double]$Quantity
    
    [int]$SourceId
    
    [int]$ArticleGroupId
    
    [int]$ArticleGroupIdExtended
    
    [ValidateNotNullOrEmpty()]
    [IcaProductRecipeReference[]]$Recipes
    
    [ValidateNotNullOrEmpty()]
    [string]$Unit
    
    [ValidateNotNullOrEmpty()]
    [string]$LatestChange # yyyy-MM-ddTHH:mm:ssZ
    
    [guid]$OfflineId # guid

    IcaProduct(
        [int]$InternalOrder,
        [string]$ProductName,
        [bool]$IsStrikedOver,
        [double]$Quantity,
        [int]$SourceId,
        [int]$ArticleGroupId,
        [int]$ArticleGroupIdExtended,
        [IcaProductRecipeReference[]]$Recipes,
        [string]$Unit,
        [string]$LatestChange, # yyyy-MM-ddTHH:mm:ssZ
        [guid]$OfflineId # guid
    ) {
        $this.InternalOrder = $InternalOrder
        $this.ProductName = $ProductName
        $this.IsStrikedOver = $IsStrikedOver
        $this.Quantity = $Quantity
        $this.SourceId = $SourceId
        $this.ArticleGroupId = $ArticleGroupId
        $this.ArticleGroupIdExtended = $ArticleGroupIdExtended
        $this.Recipes = $Recipes
        $this.Unit = $Unit
        $this.LatestChange = $LatestChange
        $this.OfflineId = $OfflineId
    }
}

function Test-IcaTicket {
    if (-not $script:CommonParams.ContainsKey('Headers')) {
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
    $AuthResponse = Invoke-WebRequest -Headers @{ 'Authorization' = "Basic $BasicAuth" } -Uri "$script:BaseURL/login"

    # Add a header with the ticket to the common parameters hashtable for splatting
    $script:CommonParams['Headers'] = @{
        'AuthenticationTicket' = $AuthResponse.Headers.AuthenticationTicket[0]
    }
}

function Disconnect-IcaAPI {
    $script:CommonParams['Headers'] = @{}    
}

function Get-IcaUserCardInfo {
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/user/cardaccounts" @script:CommonParams
}

function Get-IcaUserBonusInfo {    
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/user/minbonustransaction" @script:CommonParams | Select-Object -ExpandProperty TransactionSummaryByMonth
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
    
    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            Invoke-RestMethod "$script:BaseURL/stores/$Id" @script:CommonParams
        }
        'String' {
            Invoke-RestMethod "$script:BaseURL/stores/search?Filters&Phrase=$SearchString" @script:CommonParams
        }
        'SyncTime' {
            Invoke-RestMethod "$script:BaseURL/stores/?LastSyncDate=$($LastSyncTime.ToString('yyyy-MM-dd'))" @script:CommonParams
        }
        'User' {
            Invoke-RestMethod "$script:BaseURL/user/stores" @script:CommonParams
        }
    }
}

function Get-IcaStoreOffers {
    param (
        [Parameter(Mandatory)]
        [string[]]$StoreId
    )
    
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/offers?Stores=$($StoreId -join ',')" @script:CommonParams
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

function New-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter()]
        [int64]$StoreId = 0
    )

    Test-IcaTicket

    $OfflineId = (New-Guid).Guid

    $Body = @{
        'Title'        = $Name
        'OfflineId'    = $OfflineId
        'SortingStore' = $StoreId
        'Rows'         = @()
        'LatestChange' = Get-Date -Format 'yyyy-MM-ddThh:mm:ssZ'
    }

    $null = Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists" @script:CommonParams -Method Post -Body $Body
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

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        $ListOfflineId = Get-IcaShoppingList -Name $Name | Select-Object -ExpandProperty OfflineId
    }

    Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId" @script:CommonParams -Method Delete
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

    $Body = [ordered]@{
        'ChangedShoppingListProperties' = @{
        }
        'CreatedRows'                   = @()
        'ChangedRows'                   = @()
        'DeletedRows'                   = @($ProductOfflineId)
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body
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
    
#     $script:Headers = @{
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

#     Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body
# }

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

function Get-IcaProductGroups {
    [CmdletBinding()]
    param (
        [datetime]$LastSyncTime = (Get-Date '2001-01-01')
    )
    
    Test-IcaTicket

    $LastSyncTimeString = $LastSyncTime.ToString('yyyy-MM-dd')

    Invoke-RestMethod "$script:BaseURL/articles/articlegroups?lastsyncdate=$LastSyncTimeString" @script:CommonParams | Select-Object -ExpandProperty ArticleGroups
}

function Get-IcaProduct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'UPC', ValueFromPipeline = $true)]
        [int64[]]$UPCCode
    )
    
    Test-IcaTicket

    $LastSyncTimeString = $LastSyncTime.ToString('yyyy-MM-dd')

    switch ($PSCmdlet.ParameterSetName) {
        'All' {
            Invoke-RestMethod "$script:BaseURL/articles/articles?lastsyncdate=$LastSyncTimeString" @script:CommonParams | Select-Object -ExpandProperty Articles
        }
        'UPC' {
            Invoke-RestMethod "$script:BaseURL/upclookup?upc=$($UPCCode -join ',')" @script:CommonParams
        }
    }
}

function Get-IcaRecipe {
    param (
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$Id,

        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [switch]$GeneralOffers,

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

    # Needs [System.Net.WebUtility]::HtmlDecode for the CookingSteps property (and maybe others)

    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            if ($GeneralOffers.IsPresent) {
                return Invoke-RestMethod "$script:BaseURL/recipes/recipe/$_/generaloffers" @script:CommonParams
            }
            else {
                $Recipes = $Id | ForEach-Object { Invoke-RestMethod "$script:BaseURL/recipes/recipe/$_" @script:CommonParams }
            }
        }
        'String' {
            $Page = 0
            do {
                $Result = Invoke-RestMethod "$script:BaseURL/recipes/searchwithfilters?phrase=$SearchString&recordsPerPage=1000&pageNumber=$Page&sorting=$StoreId" @script:CommonParams
                $Page++
                $Recipes += $Result.Recipes
            } while ($Page -le $Result.NumberOfPages -and $Recipes.Count -lt $NumberOfRecipes)
            $Recipes = $Recipes | Sort-Object { Get-Random } | Select-Object -First $NumberOfRecipes
        }
        'Filter' {
            $Page = 0
            do {
                $Result = Invoke-RestMethod "$script:BaseURL/recipes/searchwithfilters?phrase=&recordsPerPage=1000&pageNumber=$Page&filters=$($Filter -join ',')&sorting=$StoreId" @script:CommonParams
                $Page++
                $Recipes += $Result.Recipes
            } while ($Page -le $Result.NumberOfPages -and $Recipes.Count -lt $NumberOfRecipes)
            $Recipes = $Recipes | Sort-Object { Get-Random } | Select-Object -First $NumberOfRecipes
        }
        'User' {
            $Recipes = Invoke-RestMethod "$script:BaseURL/user/recipes" @script:CommonParams | Select-Object -ExpandProperty UserRecipes | ForEach-Object {
                Get-IcaRecipe -Id $_.RecipeId
            }
            $NumberOfRecipes = $Recipes.Count
        }
        'Random' {
            if ($CategoryId -ge 0) {
                $Recipes = Invoke-RestMethod "$script:BaseURL/recipes/categories/general/${CategoryId}?recordsPerPage=1000&pageNumber=0" @script:CommonParams | 
                Select-Object -ExpandProperty Recipes |
                Sort-Object { Get-Random }
            }
            elseif ($Random.IsPresent) {
                Write-Warning @'
The endpoint used for random recipes is limited to only around 50 recipes at a time with a fairly sparse selection of recipes.
For a larger selection to randomize from, send an empty string using the -SearchString parameter combined with -NumberOfRecipes.
'@
                $Recipes = Invoke-RestMethod "$script:BaseURL/recipes/random?numberOfRecipes=$NumberOfRecipes" @script:CommonParams | Select-Object -ExpandProperty Recipes
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

function Save-IcaRecipe {
    param (
        [Parameter(Mandatory)]
        [int[]]$Id
    )
    
    Test-IcaTicket

    $Body = @{
        'Recipes' = @($Id)
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$script:BaseURL/user/recipes" @script:CommonParams -Method POST -Body $Body
}

function Remove-IcaRecipe {
    param (
        [Parameter(Mandatory)]
        [int[]]$Id
    )
    
    Test-IcaTicket

    Invoke-RestMethod "$script:BaseURL/user/recipes?recipes=$($Id -join ',')" @script:CommonParams -Method Delete
}

function Get-IcaRecipeFilters {    
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/recipes/search/filters" @script:CommonParams | Select-Object -ExpandProperty categories
}

function Get-IcaRecipeCategories {
    Test-IcaTicket

    # Invoke-RestMethod "$script:BaseURL/recipes/categories/general" @script:CommonParams | Select-Object -ExpandProperty Categories
    Invoke-RestMethod "$script:BaseURL/recipes/categories/puff?includeWeeklyMixCategory=true" @script:CommonParams | Select-Object -ExpandProperty Categories
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

    Invoke-RestMethod "$script:BaseURL/info/urgent" @script:CommonParams
}