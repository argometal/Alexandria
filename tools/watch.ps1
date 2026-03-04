$path = "C:\Alexandria"
$lastCommit = ""

function Get-ServerIP {
    $file = "C:\Tools\bridge\HOW_TO_USE.txt"

    if (Test-Path $file) {

        $content = Get-Content $file -Raw
  <#       Write-Host "[DEBUG] contenido leído:"
        Write-Host $content #>

        $match = [regex]::Match($content, "http://([0-9\.]+):4000")

        if ($match.Success) {
            $ip = $match.Groups[1].Value.Trim()
            Write-Host "[DEBUG] ip detectada:" $ip
            return $ip
        }
    }

    return "127.0.0.1"
}

$ip = Get-ServerIP

if (-not $ip -or $ip -eq "") {
    $ip = "127.0.0.1"
}


$ip = $ip.Trim()

Write-Host "[DEBUG] ip final:" $ip

$endpoint = "http://{0}:4000/sfs" -f $ip

Write-Host "[WATCH] endpoint $endpoint"


while ($true) {
    cd $path

    $currentCommit = git rev-parse HEAD

    if ($currentCommit -ne $lastCommit) {

        $payload = git show HEAD

        try {
            Invoke-RestMethod $endpoint -Method POST -Body $payload
            Write-Host "[WATCH][COMMIT] enviado"
            $lastCommit = $currentCommit
        } catch {
            Write-Host "[WATCH][ERR]"
        }
    }

    Start-Sleep -Seconds 2
}