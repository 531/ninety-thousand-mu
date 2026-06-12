$base = "C:/Users/531/Desktop/九萬畝"
$port = if ($env:PORT) { [int]$env:PORT } else { 3457 }
$l = [System.Net.HttpListener]::new()
$l.Prefixes.Add("http://localhost:$port/")
$l.Start()
Write-Host "Server at http://localhost:$port/"
while ($true) {
    $ctx  = $l.GetContext()
    $req  = $ctx.Request
    $resp = $ctx.Response
    try {
        $url  = $req.Url.LocalPath.TrimStart("/")
        if ($url -eq "") { $url = "index.html" }
        $file = Join-Path $base $url
        $resp.AddHeader("Access-Control-Allow-Origin", "*")
        $resp.AddHeader("Cache-Control", "no-cache")
        if ($req.HttpMethod -eq "OPTIONS") {
            $resp.StatusCode = 204
            $resp.Close()
            continue
        }
        if (Test-Path $file -PathType Leaf) {
            $ext  = [System.IO.Path]::GetExtension($file).ToLower()
            $mime = "application/octet-stream"
            if ($ext -eq ".html") { $mime = "text/html; charset=utf-8" }
            elseif ($ext -eq ".css")  { $mime = "text/css; charset=utf-8" }
            elseif ($ext -eq ".js")   { $mime = "application/javascript; charset=utf-8" }
            elseif ($ext -eq ".png")  { $mime = "image/png" }
            elseif ($ext -eq ".jpg")  { $mime = "image/jpeg" }
            $data = [System.IO.File]::ReadAllBytes($file)
            $resp.ContentType = $mime
            $resp.ContentLength64 = $data.LongLength
            if ($req.HttpMethod -ne "HEAD") {
                $resp.OutputStream.Write($data, 0, $data.Length)
            }
        } else {
            $resp.StatusCode = 404
        }
    } catch {
        # ignore client disconnect
    } finally {
        try { $resp.Close() } catch {}
    }
}