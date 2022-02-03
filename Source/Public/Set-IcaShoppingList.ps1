# Get input list, make a diff check and compose a body with created, changed and deleted rows
# function Set-IcaShoppingList {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory, ValueFromPipeline = $true)]
#         [string]$ListOfflineId,

#         [Parameter(ValueFromPipeline = $true)]
#         [string]$Name
#     )

#     Test-IcaConnection
    
#     $script:Headers = @{
#         'AuthenticationTicket' = $Ticket
#     }

#     $Body = @{
#         'ChangedShoppingListProperties' = @{
#             'Title'        = $Name
#             'LatestChange' = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
#         }
#         'CreatedRows'                   = @()
#         'ChangedRows'                   = @()
#         'DeletedRows'                   = @()
#     } | ConvertTo-Json -Depth 10 -Compress

#     Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
# }