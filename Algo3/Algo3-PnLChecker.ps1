# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
#Read Token
$token = Get-Content -Path .\token.txt
$token = "enctoken " + $token

#Get Positions
$readPositions = Get-Content -Path .\algo3-positions.json | Out-String | ConvertFrom-Json
$positions = $readPositions.data
$scrips = $positions.Symbol | Select -Unique
$strategyStatus = $readPositions.status


IF($strategyStatus -eq 'Active'){

#check individual SL hit
FOREACH($item in $scrips){
    $uri = "https://api.kite.trade/quote/ltp?i=NFO:" + $item
    $datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token}
    $LtpData =  $($datum.Content | ConvertFrom-Json).data
    $Ltp = $LtpData.psobject.properties.value.last_price
    FOREACH($pos in $positions){
        IF($pos.Symbol -eq $item){
            $pos.LTP = $Ltp
            IF($pos.isActive){
            IF($Ltp -ge $pos.StopLoss){
                $pos.BuyPrice = $Ltp
                $pos.isActive = $False

            }
            }
            IF($pos.isActive){
                $pos_pnl = ($pos.SellPrice - $ltp) * 25
                $pos.PnL = [math]::Round($pos_pnl,2)  
            }ELSE{
                $pos_pnl = ($pos.SellPrice - $pos.BuyPrice) * 25
                $pos.PnL = [math]::Round($pos_pnl,2)        
            }
        }
    }

}
$readPositions| ConvertTo-Json  | Out-File "algo3-positions.json"



$grossPnL = ($positions.PnL |Measure-Object -sum ).sum
$grossPnL = [math]::Round($grossPnL,2)

$time = Get-Date -Format "HH:mm"


IF(($grossPnL -le -3500) -or ($time -eq "09:45")){
#Exit All
    $readPositions.status = "Inactive"
    FOREACH($item in $scrips){
        $uri = "https://api.kite.trade/quote/ltp?i=NFO:" + $item
        $datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token}
        $LtpData =  $($datum.Content | ConvertFrom-Json).data
        $Ltp = $LtpData.psobject.properties.value.last_price
        FOREACH($pos in $positions){
            IF($pos.Symbol -eq $item){
                    IF($pos.isActive ){
                    $pos.BuyPrice = $Ltp
                    $pos.PnL = [math]::Round((($pos.SellPrice - $pos.BuyPrice)*25),2)
                    $pos.isActive = $False
                    }
                }
        }
    }

}

$readPositions| ConvertTo-Json | Out-File "algo3-positions.json"

$date = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( (Get-Date), 'India Standard Time')
$timer = Get-Date $date -Format "dd-MM-yyyy,HH:mm,"
$val = $timer+[string]$grossPnL
#Add-Content -Path algo3-pnl.txt -Value $val
@($val) +  (Get-Content "algo3-pnl.txt") | Set-Content "algo3-pnl.txt"
}
