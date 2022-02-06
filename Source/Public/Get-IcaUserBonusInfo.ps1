function Get-IcaUserBonusInfo {    
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('SixMonths','CurrentBonus','Transactions')]
        [string]$Type
    )

    Test-IcaConnection

    switch ($Type) {
        'SixMonths' {
            Invoke-RestMethod "$script:BaseURL/user/bonus/history/sixmonths" @script:CommonParams -ErrorAction Stop
        }
        'CurrentBonus' {
            Invoke-RestMethod "$script:BaseURL/user/bonus/getCurrentBonus" @script:CommonParams -ErrorAction Stop
        }
        'Transactions' {
            Invoke-RestMethod "$script:BaseURL/user/minbonustransaction" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty TransactionSummaryByMonth
        }
    }
}