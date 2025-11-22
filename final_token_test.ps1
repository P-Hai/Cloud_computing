Write-Host "=== FINAL KEYCLOAK TOKEN TEST ===" -ForegroundColor Cyan
Write-Host ""

# Test sv01
Write-Host "Testing user sv01..." -ForegroundColor Yellow
$body1 = @{
    username = "sv01"
    password = "sv01password"
    grant_type = "password"
    client_id = "flask-app"
}

$token1 = Invoke-RestMethod -Uri "http://localhost:8081/realms/myminicloud-realm/protocol/openid-connect/token" -Method Post -Body $body1 -ContentType "application/x-www-form-urlencoded"

$headers1 = @{
    Authorization = "Bearer $($token1.access_token)"
}

try {
    $result1 = Invoke-RestMethod -Uri "http://localhost:8085/secure" -Headers $headers1
    Write-Host " sv01 SUCCESS!" -ForegroundColor Green
    Write-Host "   Message: $($result1.message)" -ForegroundColor White
    Write-Host "   User: $($result1.preferred_username)" -ForegroundColor White
} catch {
    Write-Host " sv01 FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test sv02
Write-Host "Testing user sv02..." -ForegroundColor Yellow
$body2 = @{
    username = "sv02"
    password = "sv02password"
    grant_type = "password"
    client_id = "flask-app"
}

$token2 = Invoke-RestMethod -Uri "http://localhost:8081/realms/myminicloud-realm/protocol/openid-connect/token" -Method Post -Body $body2 -ContentType "application/x-www-form-urlencoded"

$headers2 = @{
    Authorization = "Bearer $($token2.access_token)"
}

try {
    $result2 = Invoke-RestMethod -Uri "http://localhost:8085/secure" -Headers $headers2
    Write-Host " sv02 SUCCESS!" -ForegroundColor Green
    Write-Host "   Message: $($result2.message)" -ForegroundColor White
    Write-Host "   User: $($result2.preferred_username)" -ForegroundColor White
} catch {
    Write-Host " sv02 FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST COMPLETED ===" -ForegroundColor Cyan
