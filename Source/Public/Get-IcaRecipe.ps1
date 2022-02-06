function Get-IcaRecipe {
    param (
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [int[]]$Id,

        [Parameter(ParameterSetName = 'String')]
        [AllowEmptyString()]
        [string]$SearchString = '',

        [Parameter(Mandatory, ParameterSetName = 'Filter')]
        [ValidateSet([IcaFilter])]
        [string[]]$Filter,

        [Parameter(ParameterSetName = 'String')]
        [Parameter(ParameterSetName = 'Filter')]
        [switch]$Random,

        [Parameter(Mandatory, ParameterSetName = 'User')]
        [switch]$SavedByUser,

        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'LegacyRandom')]
        [Parameter(ParameterSetName = 'String')]
        [int]$NumberOfRecipes = 1,

        [Parameter(ParameterSetName = 'Filter')]
        [Parameter(ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'LegacyRandom')]
        [Parameter(ParameterSetName = 'String')]
        [switch]$Full,

        [Parameter(ParameterSetName = 'String')]
        [Parameter(ParameterSetName = 'Filter')]
        [IcaSorting]$Sorting = [int][IcaSorting]::Relevance,

        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [switch]$GeneralOffers,

        [Parameter(Mandatory, ParameterSetName = 'Category')]
        [Parameter(ParameterSetName = 'LegacyRandom', DontShow)]
        [int]$CategoryId = 0,

        [Parameter(Mandatory, ParameterSetName = 'LegacyRandom', DontShow)]
        [switch]$LegacyRandom
    )
    
    Test-IcaConnection

    # Get batches of 1000 if the number of recipes requested is greater than 1000
    if ($Random.IsPresent) {
        $RecordsPerPage = 1000
    }
    else {
        $RecordsPerPage = [math]::Min($NumberOfRecipes, 1000)
    }
    $Page = 0

    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            if ($GeneralOffers.IsPresent) {
                return Invoke-RestMethod "$script:BaseURL/recipes/recipe/$_/generaloffers" @script:CommonParams -ErrorAction Stop
            }
            else {
                $Recipes = $Id | ForEach-Object { Invoke-RestMethod "$script:BaseURL/recipes/recipe/$_" @script:CommonParams -ErrorAction Stop }
            }
        }
        { $_ -eq 'String' -or $_ -eq 'Filter' } {
            switch ($PSCmdlet.ParameterSetName) {
                'String' {
                    $Url = "$script:BaseURL/recipes/searchwithfilters?phrase=$SearchString&recordsPerPage=$RecordsPerPage&pageNumber=$Page&sorting=$([int]$Sorting)"
                    Write-Debug "Url = $Url"
                }
                'Filter' {
                    $Url = "$script:BaseURL/recipes/searchwithfilters?phrase=&recordsPerPage=$RecordsPerPage&pageNumber=$Page&filters=$($Filter -join ',')&sorting=$([int]$Sorting)"
                    Write-Debug "Url = $Url"
                }
            }

            # If Random is selected, randomize between up to 1000 recepies within filters or search
            if ($Random.IsPresent) {
                $OriginalNumberOfRecipes = $NumberOfRecipes
                $NumberOfRecipes = 1000
            }

            do {
                $Result = Invoke-RestMethod $Url @script:CommonParams -ErrorAction Stop
                $Page++
                $Recipes += $Result.Recipes
            } while ($Page -le $Result.NumberOfPages -and $Recipes.Count -lt $NumberOfRecipes)

            # If Random is selected, reset the number of recipes to the original value
            if ($Random.IsPresent) {
                $NumberOfRecipes = $OriginalNumberOfRecipes
            }

            $Recipes = $Recipes |
            Sort-Object { Get-Random } |
            Select-Object -First $NumberOfRecipes
        }
        'User' {
            $Recipes = Invoke-RestMethod "$script:BaseURL/user/recipes" @script:CommonParams -ErrorAction Stop |
            Select-Object -ExpandProperty UserRecipes |
            ForEach-Object {
                Get-IcaRecipe -Id $_.RecipeId -ErrorAction Stop
            }
            $NumberOfRecipes = $Recipes.Count
        }
        'LegacyRandom' {
            if ($CategoryId -gt 0) {
                $Recipes = Invoke-RestMethod "$script:BaseURL/recipes/categories/general/${CategoryId}?recordsPerPage=1000&pageNumber=0" @script:CommonParams -ErrorAction Stop | 
                Select-Object -ExpandProperty Recipes |
                Sort-Object { Get-Random } |
                Select-Object -First $NumberOfRecipes
            }
            elseif ($LegacyRandom.IsPresent) {
                Write-Warning @'
The endpoint used for random recipes is limited to only around 50 recipes at a time with a fairly sparse selection of recipes.
For a larger selection to randomize from, use the -Random parameter combined with -NumberOfRecipes.
'@
                $Recipes = Invoke-RestMethod "$script:BaseURL/recipes/random?numberOfRecipes=$NumberOfRecipes" @script:CommonParams -ErrorAction Stop |
                Select-Object -ExpandProperty Recipes |
                Sort-Object { Get-Random } |
                Select-Object -First $NumberOfRecipes
            }
            else {
                throw 'Parameter combination not supported!'
            }
        }
    }

    if ($Full.IsPresent) {
        Write-Warning "The Full parameter means that one extra request to the ICA API will be made for each recipe found, up to $NumberOfRecipes (NumberOfRecipes). This can take a while."
        $Recipes = $Recipes | ForEach-Object { Get-IcaRecipe -Id $_.Id -ErrorAction Stop }
    }

    Write-Output $Recipes
}