# Load the .NET assembly required for web operations
Add-Type -AssemblyName System.Web

# Print the script header with color styling to the console
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Goyfield Gacha URL Extractor" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Define the path to the game's Chromium web cache file (data_1)
$logLocation = "$env:USERPROFILE\AppData\Local\PlatformProcess\Cache\data_1"

# Define the API host we are targeting for validation
$apiHost = "ef-webview.gryphline.com"

# Check if the cache file actually exists at the defined path
if (-Not (Test-Path $logLocation)) {
    # Print an error message if the file is missing
    Write-Host "Cannot find log file!" -ForegroundColor Red
    
    # Show the user where we expected to find the file
    Write-Host "Expected location: $logLocation" -ForegroundColor Yellow
    Write-Host ""
    
    # Remind the user to open the history in the game first
    Write-Host "Make sure you have opened gacha history in game first!" -ForegroundColor Yellow
    
    # Exit the script since we can't proceed
    return
}

# Notify the user that the file was successfully found
Write-Host "Found log file: $logLocation" -ForegroundColor Green
Write-Host "Reading log..." -ForegroundColor Cyan
Write-Host ""

# Attempt to read the file contents
try {
    # Read the entire binary cache file as a raw text string
    $logContent = Get-Content -Path $logLocation -Raw -ErrorAction Stop
}
catch {
    # If reading fails, print the error and exit
    Write-Host "Failed to read log file!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Define the regular expression to find the gacha URL inside the binary data
# We only match valid URL characters [a-zA-Z0-9/_\-\.\?=&%] so the regex stops at binary garbage
$urlPattern = "(https://ef-webview\.gryphline\.com[a-zA-Z0-9/_\-\.\?=&%]+u8_token=[a-zA-Z0-9/_\-\.\?=&%]+)"

# Search the entire file content for all strings matching our pattern
$allMatches = [regex]::Matches($logContent, $urlPattern)

# Check if we found at least one matching URL
if ($allMatches.Count -gt 0) {
    # Select the very last match in the file (this represents the most recent history load)
    $lastMatch = $allMatches[$allMatches.Count - 1]
    
    # Extract the exact matched string (the URL)
    $fullUrl = $lastMatch.Groups[1].Value
    
    # Notify the user that a URL was found
    Write-Host "Found gacha URL in log!" -ForegroundColor Green
    Write-Host ""
    
    # Look specifically for the 'u8_token' parameter inside the found URL
    if ($fullUrl -match "u8_token=([^&\s]+)") {
        # Extract and save the token value
        $token = $matches[1]
        
        # Set a default server ID (3 is commonly used)
        $server = "3" 
        
        # Try to find the actual server ID parameter in the URL
        if ($fullUrl -match "server=(\d+)") {
            # If found, update the server variable
            $server = $matches[1]
        }
        
        # Construct the final API URL needed for the tracker using the token and server
        $apiUrl = "https://ef-webview.gryphline.com/api/record/char?lang=en-us&pool_type=E_CharacterGachaPoolType_Beginner&token=$token&server_id=$server"
        
        # Notify the user that we are testing the constructed URL
        Write-Host "Validating URL..." -ForegroundColor Cyan
        try {
            # Send a test web request to the API and parse the JSON response
            $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -TimeoutSec 10 | ConvertFrom-Json
            
            # Check if the API returned a success code (0 means OK)
            if ($response.code -eq 0) {
                Write-Host "URL is valid!" -ForegroundColor Green
            }
            else {
                # Warn the user if the API returned an error code
                Write-Host "URL validation returned code: $($response.code)" -ForegroundColor Yellow
            }
        }
        catch {
            # Warn if the web request failed completely (e.g., no internet connection)
            Write-Host "Could not validate URL" -ForegroundColor Yellow
        }
        
        # Print success headers
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host "SUCCESS! URL extracted and copied!" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Display the originally extracted URL for debugging purposes
        Write-Host "Full URL:" -ForegroundColor White
        Write-Host $fullUrl -ForegroundColor Gray
        Write-Host ""
        
        # Display the final Tracker-ready API URL
        Write-Host "API URL (for Arknights Tracker):" -ForegroundColor White
        Write-Host $apiUrl -ForegroundColor White
        Write-Host ""
        
        # Copy the final API URL directly to the user's Windows clipboard
        Set-Clipboard -Value $apiUrl
        
        # Notify the user that they can now paste the link
        Write-Host "API URL copied to clipboard!" -ForegroundColor Green
        Write-Host "You can paste it into Goyfield." -ForegroundColor Green
    }
    else {
        # If we found a URL but couldn't parse the token out of it
        Write-Host "Found URL but couldn't extract token!" -ForegroundColor Red
        Write-Host $fullUrl -ForegroundColor Yellow
    }
}
else {
    # If the regex found absolutely nothing in the file
    Write-Host "No gacha URL found in log file!" -ForegroundColor Red
    Write-Host ""
    
    # Print step-by-step troubleshooting instructions for the user
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Open Endfield" -ForegroundColor Yellow
    Write-Host "2. Go to gacha/summon screen" -ForegroundColor Yellow
    Write-Host "3. Open gacha history" -ForegroundColor Yellow
    Write-Host "4. Run this script again" -ForegroundColor Yellow
    Write-Host ""
    
    # Explain why these steps are necessary
    Write-Host "The URL is logged when you open the gacha history screen." -ForegroundColor Cyan
}
