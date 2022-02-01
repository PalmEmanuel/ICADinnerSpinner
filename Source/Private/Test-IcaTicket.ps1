function Test-IcaTicket {
    if (-not $script:CommonParams.ContainsKey('Headers')) {
        throw 'Please run Connect-IcaAPI before using this command.'
    }
}