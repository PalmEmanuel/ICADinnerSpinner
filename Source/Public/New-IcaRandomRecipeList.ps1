function New-IcaRandomRecipeList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [ValidateSet([IcaFilter])]
        [string[]]$Filter,

        [Parameter(Mandatory, ParameterSetName = 'Random')]
        [switch]$Random,

        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'Random')]
        [int]$StoreId = 0
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Filter' {
            $Recipe = Get-IcaRecipe -Filter $Filter -Random -NumberOfRecipes 1 -StoreId $StoreId -ErrorAction Stop -Full
        }
        'Random' {
            $Recipe = Get-IcaRecipe -SearchString '' -Random -NumberOfRecipes 1 -StoreId $StoreId -ErrorAction Stop -Full
        }
    }

    if ($Recipe.Count -eq 0) {
        throw 'No recipe found!'
    }

    $LatestChangeString = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'

    $Products = Get-IcaProduct

    $Ingredients = $Recipe.IngredientGroups | ForEach-Object {
        $_.Ingredients | ForEach-Object -Begin { $InternalOrder = 1 } -Process {
            $CurrentIngredient = $_
            $CurrentProduct = $Products | Where-Object {
                $_.Name -eq $CurrentIngredient.Ingredient -or
                $_.PluralName -eq $CurrentIngredient.Ingredient
            }

            # If a product was found, get the group/parent id, used for the store organising sections in list
            if ($CurrentProduct.Count -gt 0) {
                $ProductGroupId = $CurrentProduct.ParentId
                $ProductGroupIdExtended = $CurrentProduct.ParentIdExtended
            }
            else {
                $ProductGroupId = -1
                $ProductGroupIdExtended = -1
            }

            # Unit can be null, set to empty string in that case
            if (-not [string]::IsNullOrWhiteSpace($CurrentIngredient.Unit)) {
                $UnitString = $CurrentIngredient.Unit 
            }
            else { $UnitString = '' }

            $RecipeReference = New-Object IcaProductRecipeReference -ArgumentList @(
                $Recipe.Id,
                $CurrentIngredient.Quantity,
                $UnitString
            ) -ErrorAction Stop

            $Guid = New-Guid

            # Create and output the product
            New-Object IcaProduct -ArgumentList @(
                $InternalOrder,
                $CurrentIngredient.Ingredient, # ProductName
                $false, # IsStrikedOver
                $CurrentIngredient.Quantity,
                $UnitString, # Unit
                $CurrentIngredient.IngredientId, # SourceId
                $ProductGroupId, # ArticleGroupId
                $ProductGroupIdExtended, # ArticleGroupIdExtended
                $RecipeReference, # IcaProductRecipeReference
                $LatestChangeString,
                $Guid
            ) -ErrorAction Stop

            $InternalOrder++
        }
    }

    $Stars = [math]::Floor($Recipe.AverageRating)
    $EmptyStars = 5 - $Stars
    $StarsString = "$('★' * $Stars)$('☆' * $EmptyStars) ($($Recipe.CurrentUsersRating))"

    $ListId = New-IcaShoppingList -Name "$($Recipe.Title) - $StarsString" -StoreId $StoreId -ErrorAction Stop

    Add-IcaShoppingListItem -ListOfflineId $ListId -Product $Ingredients
}