# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
#Read Token
$token = Get-Content -Path .\token.txt
$token = "enctoken " + $token

$myPostions = $(Get-Content -Path .\algo2-positions.json | ConvertFrom-Json)
$positionData = $myPostions.data

IF($myPostions.status -eq "Active"){
#Update LTP
$adjustment = $false
$sellRate = 0
$currRate = 0
$priceArray = @()
FOREACH($item in $positionData){
    $uri = "https://api.kite.trade/quote/ltp?i=NFO:" + $item.Symbol
    $datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token} 
    $LtpData =  $($datum.Content | ConvertFrom-Json).data
    $Ltp = $LtpData.psobject.properties.value.last_price
    $item.LTP = $Ltp
    IF($item.isActive){
        $item.PnL = [math]::Round((($item.SellPrice - $Ltp)*25),2)
    }
    $sellRate = $sellRate + $item.SellPrice
    $currRate = $currRate + $item.LTP
    $priceArray = $priceArray + $item.LTP

}

$myPostions| ConvertTo-Json | Out-File "algo2-positions.json"

$grossPnL = ($positionData.PnL |Measure-Object -sum ).sum
$grossPnL = [math]::Round($grossPnL,2)

$date = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( (Get-Date), 'India Standard Time')
$timer = Get-Date $date -Format "dd-MM-yyyy,HH:mm,"
$val = $timer+[string]$grossPnL
#Add-Content -Path algo2-pnl.txt -Value $val
@($val) +  (Get-Content "algo2-pnl.txt") | Set-Content "algo2-pnl.txt"



$factor = $priceArray[0]/$priceArray[1]
IF(($factor -ge 0.4) -and ($factor -le 2.5)){
    $adjustment = $false
}

#Check SL
IF($currRate -gt $sellRate * 1.7){
    $myPostions.status = "Inactive"
    FOREACH($item in $positionData){
        $uri = "https://api.kite.trade/quote/ltp?i=NFO:" + $item.Symbol
        $datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token} 
        $LtpData =  $($datum.Content | ConvertFrom-Json).data
        $Ltp = $LtpData.psobject.properties.value.last_price
        $item.LTP = $Ltp
        $item.BuyPrice = $Ltp
        $item.isActive = $False
        $item.PnL = [math]::Round((($item.SellPrice - $Ltp)*25),2)
    }
}
}
$myPostions| ConvertTo-Json | Out-File "algo2-positions.json"

