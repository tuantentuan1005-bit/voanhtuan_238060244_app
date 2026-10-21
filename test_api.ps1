$body = @{
    email = "admin@diemdanh.edu.vn"
    maOtp = "123456"
} | ConvertTo-Json

try {
    $res = Invoke-RestMethod -Uri "http://localhost:5226/api/auth/verify-otp" -Method Post -ContentType "application/json" -Body $body
    $res | ConvertTo-Json -Depth 6
} catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $reader.ReadToEnd()
}
