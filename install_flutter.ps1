$url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip"
$output = "flutter.zip"
Write-Host "Downloading Flutter..."
Invoke-WebRequest -Uri $url -OutFile $output
Write-Host "Extracting Flutter..."
Expand-Archive -Path $output -DestinationPath "flutter_sdk"
Write-Host "Done!"
