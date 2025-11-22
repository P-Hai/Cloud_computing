Write-Host "=== DETAILED KEYCLOAK TEST ===" -ForegroundColor Cyan
Write-Host ""

# 1. Get token
Write-Host "1. Getting token from Keycloak..." -ForegroundColor Yellow

$body = @{
    username = "sv01"
    password = "sv01password"
    grant_type = "password"
    client_id = "flask-app"
}

$tokenUrl = "http://localhost:8081/realms/myminicloud-realm/protocol/openid-connect/token"
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

Write-Host "    Token received" -ForegroundColor Green
$token = $tokenResponse.access_token

# 2. Decode token (just header and payload, not signature)
Write-Host ""
Write-Host "2. Decoding token..." -ForegroundColor Yellow
$parts = $token.Split('.')
$header = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($parts[0] + "=="))
$payload = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($parts[1] + "=="))

Write-Host "   Header:" -ForegroundColor Gray
$header | ConvertFrom-Json | ConvertTo-Json | Write-Host

Write-Host ""
Write-Host "   Payload (relevant fields):" -ForegroundColor Gray
$payloadObj = $payload | ConvertFrom-Json
Write-Host "   - Issuer: $($payloadObj.iss)" -ForegroundColor White
Write-Host "   - Subject: $($payloadObj.sub)" -ForegroundColor White
Write-Host "   - Preferred Username: $($payloadObj.preferred_username)" -ForegroundColor White
Write-Host "   - Audience: $($payloadObj.aud)" -ForegroundColor White
Write-Host "   - Expiry: $($payloadObj.exp)" -ForegroundColor White

# 3. Check Flask app environment
Write-Host ""
Write-Host "3. Checking Flask app configuration..." -ForegroundColor Yellow
docker exec application-backend-server printenv | Select-String "OIDC"

# 4. Test /hello (no auth)
Write-Host ""
Write-Host "4. Testing /hello endpoint (no auth)..." -ForegroundColor Yellow
try {
    $hello = Invoke-RestMethod -Uri "http://localhost:8085/hello"
    Write-Host "    /hello works: $($hello.message)" -ForegroundColor Green
} catch {
    Write-Host "    /hello failed" -ForegroundColor Red
}

# 5. Test /secure with token
Write-Host ""
Write-Host "5. Testing /secure endpoint with token..." -ForegroundColor Yellow

$headers = @{
    Authorization = "Bearer $token"
}

try {
    $secure = Invoke-RestMethod -Uri "http://localhost:8085/secure" -Headers $headers
    Write-Host "    SUCCESS!" -ForegroundColor Green
    $secure | ConvertTo-Json | Write-Host
} catch {
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Checking Flask logs..." -ForegroundColor Yellow
    docker logs application-backend-server --tail 20
}

Write-Host ""
Write-Host "=== TEST COMPLETED ===" -ForegroundColor Cyan
