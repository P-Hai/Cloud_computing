Write-Host "=== FIXING KEYCLOAK INTEGRATION ===" -ForegroundColor Cyan

# 1. Update docker-compose.yml
Write-Host "`n1. Updating docker-compose.yml..." -ForegroundColor Yellow
$compose = Get-Content docker-compose.yml -Raw
$compose = $compose -replace 'OIDC_ISSUER: "http://authentication-identity-server:8080/realms/master"', 'OIDC_ISSUER: "http://authentication-identity-server:8080/realms/myminicloud-realm"'
$compose = $compose -replace 'OIDC_AUDIENCE: "myapp"', 'OIDC_AUDIENCE: "account"'
Set-Content docker-compose.yml -Value $compose -NoNewline
Write-Host "    Updated" -ForegroundColor Green

# 2. Restart container
Write-Host "`n2. Restarting application-backend-server..." -ForegroundColor Yellow
docker-compose stop application-backend-server
docker-compose rm -f application-backend-server
docker-compose up -d application-backend-server
Start-Sleep -Seconds 8
Write-Host "    Restarted" -ForegroundColor Green

# 3. Verify
Write-Host "`n3. Verifying configuration..." -ForegroundColor Yellow
docker exec application-backend-server printenv | Select-String "OIDC"

Write-Host "`n=== FIX COMPLETED ===" -ForegroundColor Cyan
Write-Host "Now run: .\final_token_test.ps1" -ForegroundColor Yellow
