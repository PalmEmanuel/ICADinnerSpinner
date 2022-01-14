$BaseURL = 'https://handla.api.ica.se/api'

$BasicAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes((Get-Content .\Credentials.txt)))
$AuthResponse = Invoke-WebRequest -Headers @{ 'Authorization' = "Basic $BasicAuth" } -Uri "$BaseURL/login"
$Ticket = $AuthResponse.Headers.AuthenticationTicket[0]

#iOS is crap. - $AuthResponse.Headers.SessionTicket

$Headers = @{
    'AuthenticationTicket' = $Ticket
}

# Ica Kvantum Södermalm 16791
$Stores = Invoke-RestMethod "$BaseUrl/stores/search?Filters&Phrase=Kvantum Södermalm" -Headers $Headers
$StoreId = $Stores.Stores[0]

$StoreInfo = Invoke-RestMethod "$BaseURL/stores/$StoreId" -Headers $Headers

$Offers = Invoke-RestMethod "$BaseURL/offers?stores=$StoreId" -Headers $Headers

$ShoppingLists = Invoke-RestMethod 'https://handla.api.ica.se/api/user/offlineshoppinglists' -Headers $Headers

# Autentisering
# GET /api/login
# Kort
# GET /api/user/cardaccounts
# Min Bonus
# GET /api/user/minbonustransaction
# Affärer
# GET /api/user/stores
# GET /api/stores/1
# GET /api/stores/?LastSyncDate={timestamp}
# GET /api/stores/search?Filters&Phrase={phrase}
# Erbjudanden
# GET /api/offers?Stores=XXXX
# Inköpslistor
# Artikelgrupper
# GET /api/articles/articlegroups?lastsyncdate={timestamp}
# Vanliga artiklar
# GET /api/user/commonarticles/ + Request + Response
# Recept
# GET /api/user/recipes
# GET /api/recipes/searchwithfilters?phrase={phrase}&recordsPerPage=x&pageNumber=x&sorting=x
# GET /api/recipes/search/filters
# GET /api/recipes/recipe/XXXXXX
# GET /api/recipes/XXXXXX/rating
# GET /api/recipes/random?numberofrecipes=x
# Receptkategorier
# GET /api/recipes/categories/general
# GET /api/recipes/categories/general/{categoryId}?RecordsPerPage=x&PageNumber=x&Include=ImageId,Title,CookingTime,AverageRating,OfferCount,- IngredientCount
# GET /api/recipes/categories/general/X?PageNumber=X&RecordsPerPage=X
# Strekkodssökning
# GET /api/upclookup
# Status
# GET /api/status + Request + Response