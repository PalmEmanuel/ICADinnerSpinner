function Get-IcaUserBonusInfo {    
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/user/minbonustransaction" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty TransactionSummaryByMonth
}