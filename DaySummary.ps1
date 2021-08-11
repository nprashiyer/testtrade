# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$data = $(Get-Content -Path "pnl.txt")[0]
$algo1 = $data.Split(',')[-1]

$data = $(Get-Content -Path "algo2-pnl.txt")[0]
$algo2 = $data.Split(',')[-1]

$data = $(Get-Content -Path "algo3-pnl.txt")[0]
$algo3 = $data.Split(',')[-1]

$date = Get-Date -Format "dd/MM/yyyy"
$msg = "$date SUMMARY
===================
Algo 1 = $algo1
Algo 3 = $algo2
Algo 3 = $algo3
"

$BotToken = "1773639028:AAHAvXnZQ7jl5f5av0mJpQXc6acht92XW4Uaa"
$ChatID = "-100140608717511"

$payload = @{
        "chat_id"= $ChatID;
        "text" = $msg;
}
$sendMessage = Invoke-RestMethod -Uri ("https://api.telegram.org/bot{0}/sendMessage" -f $BotToken) `
                    -Method Post `
                    -ContentType "application/json" `
                    -Body (ConvertTo-Json -Compress -InputObject $payload) `
                    -ErrorAction Stop `
                    -UseBasicParsing
