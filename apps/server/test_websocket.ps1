# Test WebSocket connection with valid token
$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkZXZpY2VfaWQiOiJ0ZXN0LWRldmljZS0xIiwiZXhwIjoxNzY4NjQ2ODkxLCJpYXQiOjE3Njg1NjA0OTF9.YjIbpCr_E5FYkP4WJbmD5YTD0_kS3RMhsNzlfa9coqw"
Write-Host "Testing WebSocket with VALID token..."
Write-Host "URL: ws://localhost:8081/ws?token=$token"
Write-Host ""
Write-Host "Testing WebSocket without token..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/ws" -Method Get
    Write-Host "Status: $($response.StatusCode)"
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Message)"
}
Write-Host ""
Write-Host "Testing WebSocket with INVALID token..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/ws?token=invalid" -Method Get
    Write-Host "Status: $($response.StatusCode)"
} catch {
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__) - $($_.Exception.Message)"
}
