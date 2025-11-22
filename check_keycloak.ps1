Write-Host "=== CHECKING KEYCLOAK STATUS ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check container status
Write-Host "1. Container Status:" -ForegroundColor Yellow
$container = docker ps -a --filter "name=authentication-identity-server" --format "{{.Status}}"
Write-Host "   $container" -ForegroundColor $(if($container -like "*Up*"){"Green"}else{"Red"})

# 2. Check port mapping
Write-Host "`n2. Port Mapping:" -ForegroundColor Yellow
docker port authentication-identity-server 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "    Container not running!" -ForegroundColor Red
}

# 3. Check if port 8081 is listening
Write-Host "`n3. Port 8081 Status:" -ForegroundColor Yellow
$portCheck = Test-NetConnection -ComputerName localhost -Port 8081 -WarningAction SilentlyContinue
if ($portCheck.TcpTestSucceeded) {
    Write-Host "    Port 8081 is open" -ForegroundColor Green
} else {
    Write-Host "    Port 8081 is closed" -ForegroundColor Red
}

# 4. Try to connect
Write-Host "`n4. HTTP Connection Test:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081" -TimeoutSec 10 -UseBasicParsing
    Write-Host "    Keycloak is responding! Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "    Cannot connect: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n5. Last 20 lines of logs:" -ForegroundColor Yellow
    docker logs authentication-identity-server --tail 20
}

Write-Host "`n=== CHECK COMPLETED ===" -ForegroundColor Cyan
