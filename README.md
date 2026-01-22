# arknights-pull-url
Get pulls fron Arknights Endfield

### Usage

1. Open PowerShell (Press Win + R, type powershell, and hit Enter)
2. Paste command below

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex "&{$((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ivaqis/arknights-pull-url/refs/heads/main/endfield-url.ps1'))}"
```
