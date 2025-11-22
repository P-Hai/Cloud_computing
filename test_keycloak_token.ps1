Write-Host "=== TESTING KEYCLOAK TOKEN AUTHENTICATION ===" -ForegroundColor Cyan
Write-Host ""

# Test sv01
Write-Host "1. Testing user: sv01" -ForegroundColor Yellow
Write-Host "   Requesting access token..." -ForegroundColor Gray

$body = @{
    username = "sv01"
    password = "sv01password"
    grant_type = "password"
    client_id = "flask-app"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "http://localhost:8081/realms/myminicloud-realm/protocol/openid-connect/token" -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    
    Write-Host "    Token received!" -ForegroundColor Green
    Write-Host "   Token type: $($tokenResponse.token_type)" -ForegroundColor Gray
    Write-Host "   Expires in: $($tokenResponse.expires_in) seconds" -ForegroundColor Gray
    Write-Host "   Token (first 100 chars):" -ForegroundColor Gray
    Write-Host "   $($tokenResponse.access_token.Substring(0, 100))..." -ForegroundColor DarkGray
    
    # Test secure endpoint
    Write-Host ""
    Write-Host "2. Testing /secure endpoint" -ForegroundColor Yellow
    
    $headers = @{
        Authorization = "Bearer $($tokenResponse.access_token)"
    }
    
    $secureResponse = Invoke-RestMethod -Uri "http://localhost:8085/secure" -Headers $headers -Method Get
    
    Write-Host "    Secure endpoint OK!" -ForegroundColor Green
    Write-Host "   Response:" -ForegroundColor Gray
    $secureResponse | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White
    
} catch {
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

# Test sv02
Write-Host ""
Write-Host "3. Testing user: sv02" -ForegroundColor Yellow

$body2 = @{
    username = "sv02"
    password = "sv02password"
    grant_type = "password"
    client_id = "flask-app"
}

try {
    $tokenResponse2 = Invoke-RestMethod -Uri "http://localhost:8081/realms/myminicloud-realm/protocol/openid-connect/token" -Method Post -Body $body2 -ContentType "application/x-www-form-urlencoded"
    
    Write-Host "    Token received for sv02!" -ForegroundColor Green
    Write-Host "   Token (first 100 chars):" -ForegroundColor Gray
    Write-Host "   $($tokenResponse2.access_token.Substring(0, 100))..." -ForegroundColor DarkGray
    
} catch {
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== TEST COMPLETED ===" -ForegroundColor Cyan
