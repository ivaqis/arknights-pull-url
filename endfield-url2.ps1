# Define the path to the target cache file using the local app data environment variable
$filePath = "$env:LocalAppData\PlatformProcess\Cache\data_1"

# Start a try-catch block to handle any potential errors during file operations
try {
    # Set the file mode to open an existing file
    $fileMode   = [System.IO.FileMode]::Open
    
    # Set file access rights to read-only
    $fileAccess = [System.IO.FileAccess]::Read
    
    # Allow other processes to read, write, or delete the file while we have it open (prevents locking issues)
    $fileShare  = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
    
    # Create a FileStream object to safely open and read the file with the specified permissions
    $stream = New-Object System.IO.FileStream($filePath, $fileMode, $fileAccess, $fileShare)
    
    # Create an empty byte array exactly the size of the file to hold its contents
    $bytes = New-Object byte[] $stream.Length
    
    # Read the entire file stream into the byte array and suppress the console output (Out-Null)
    $stream.Read($bytes, 0, $stream.Length) | Out-Null
    
    # Close the file stream to release system resources
    $stream.Close()
    
    # Convert the raw byte array into an ASCII text string
    $data = [System.Text.Encoding]::ASCII.GetString($bytes)
    
    # Use Regular Expressions to find all occurrences of "u8_token=" and capture the value after it
    $matches = [regex]::Matches($data, "u8_token=([^&\s\x00]+)")

    # Check if at least one token was successfully found in the file
    if ($matches.Count -gt 0) {
        # Print a success message to the console in green text
        Write-Host "✅ Copy success" -ForegroundColor Green
        
        # Extract the captured value (Group 1) of the VERY LAST matched token in the file
        $token = $matches[$matches.Count - 1].Groups[1].Value
        
        # Print the extracted token wrapped in quotes to the console in dark cyan text
        Write-Host "`"$token`"" -ForegroundColor DarkCyan
        
        # Copy the extracted token directly to the Windows clipboard
        Set-Clipboard -Value $token
    } else {
        # If no tokens were found, print a failure message to the console in red text
        Write-Host "❌ Copy failure" -ForegroundColor Red
    }
} catch {
    # Catch and display any errors (like "file not found" or permission issues) in red text
    Write-Host "An error occurred while loading or processing the file: $_" -ForegroundColor Red
}
