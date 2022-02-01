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