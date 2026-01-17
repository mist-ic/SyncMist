$body = @{
    device_id = "test-device-1"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8081/register" -Method Post -Body $body -ContentType "application/json"
Write-Host "Token received:"
$response.token
