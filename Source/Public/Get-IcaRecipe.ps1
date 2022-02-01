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