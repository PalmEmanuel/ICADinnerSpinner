function Connect-IcaAPI {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [securestring]$Password
    )

    $BasicAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${UserName}:$(ConvertFrom-SecureString $Password -AsPlainText)"))
    $AuthResponse = Invoke-WebRequest -Headers @{ 'Authorization' = "Basic $BasicAuth" } -Uri "$script:BaseURL/login" -ErrorAction Stop

    # Add a header with the ticket to the common parameters hashtable for splatting
    $script:CommonParams['Headers'] = @{
        'AuthenticationTicket' = $AuthResponse.Headers.AuthenticationTicket[0]
    }
}