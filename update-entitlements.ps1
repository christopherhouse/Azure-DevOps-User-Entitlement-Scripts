[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Organization,
    
    [Parameter(Mandatory = $true)]
    [string]$UserName,
    
    [Parameter(Mandatory = $true)]
    [string]$Pat,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("stakeholder", "express", "advanced", "earlyAdopter")]
    [string]$LicenseType
)

# Create base64 encoded auth header for PAT
$encodedPat = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$Pat"))

# Get user GUID from username
Write-Host "`n🔍 " -NoNewline -ForegroundColor Cyan
Write-Host "Searching for user: " -NoNewline -ForegroundColor White
Write-Host $UserName -ForegroundColor Yellow

try {
    # Get user entitlement by filtering for the specific user
    $entitlementsUrl = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements?api-version=7.1&`$filter=name eq '$UserName'"
    $entitlementsResponse = Invoke-RestMethod -Uri $entitlementsUrl -Method Get -Headers @{
        Authorization = "Basic $encodedPat"
        "Content-Type" = "application/json"
    }
    
    if ($entitlementsResponse.totalCount -eq 0) {
        throw "User '$UserName' not found in organization '$Organization'"
    }
    
    $userEntitlement = $entitlementsResponse.items[0]
    
    $userId = $userEntitlement.id
    Write-Host "`n✅ " -NoNewline -ForegroundColor Green
    Write-Host "Found user: " -NoNewline -ForegroundColor White
    Write-Host "$($userEntitlement.user.displayName)" -NoNewline -ForegroundColor Yellow
    Write-Host " (" -NoNewline -ForegroundColor White
    Write-Host "$($userEntitlement.user.mailAddress)" -NoNewline -ForegroundColor Cyan
    Write-Host ")" -ForegroundColor White
    Write-Host "🆔 User GUID: " -NoNewline -ForegroundColor White
    Write-Host $userId -ForegroundColor Green
    
    # Display current access level
    Write-Host "`n📊 Current Access Level:" -ForegroundColor Magenta
    Write-Host "  🎫 License Type: " -NoNewline -ForegroundColor White
    Write-Host "$($userEntitlement.accessLevel.accountLicenseType)" -ForegroundColor Yellow
    Write-Host "  📝 License Display Name: " -NoNewline -ForegroundColor White
    Write-Host "$($userEntitlement.accessLevel.licenseDisplayName)" -ForegroundColor Cyan
    Write-Host "  📈 Status: " -NoNewline -ForegroundColor White
    Write-Host "$($userEntitlement.accessLevel.status)" -ForegroundColor Green
    Write-Host "  🔗 Licensing Source: " -NoNewline -ForegroundColor White
    Write-Host "$($userEntitlement.accessLevel.licensingSource)" -ForegroundColor Blue
    
    # Construct URL inside try block to ensure variable scope
    Write-Host "`n🔗 Constructing API URL..." -ForegroundColor Magenta
    Write-Host "🆔 User ID: " -NoNewline -ForegroundColor White
    Write-Host $userId -ForegroundColor Green
    $url = "https://vsaex.dev.azure.com/$Organization/_apis/userentitlements/$($userId)?api-version=7.1"
    Write-Host "🌐 URL: " -NoNewline -ForegroundColor White
    Write-Host $url -ForegroundColor Cyan
    
    # Prepare body - Use JSON Patch format (must be an array)
    $patchOperation = @{
        op = "replace"
        path = "/accessLevel"
        value = @{
            accountLicenseType = $LicenseType
        }
    }
    $body = @($patchOperation)
    $jsonBody = $body | ConvertTo-Json -Depth 3 -AsArray

    # Execute PATCH
    Write-Host "`n📤 Request Body:" -ForegroundColor Magenta
    Write-Host $jsonBody -ForegroundColor Gray
    
    Write-Host "`n🚀 " -NoNewline -ForegroundColor Green
    Write-Host "Updating user entitlement to: " -NoNewline -ForegroundColor White
    Write-Host $LicenseType -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri $url -Method Patch -Body $jsonBody -Headers @{
      Authorization = "Basic $encodedPat"
      "Content-Type" = "application/json-patch+json"
    }

    # Check if the update was successful
    if ($response.isSuccess -eq $false) {
        Write-Host "`n❌ " -NoNewline -ForegroundColor Red
        Write-Host "Update failed!" -ForegroundColor White
        if ($response.operationResults) {
            Write-Host "`n🔍 Error details:" -ForegroundColor Yellow
            
            # Create array to hold error data for table
            $errorData = @()
            
            foreach ($operationResult in $response.operationResults) {
                if ($operationResult.errors) {
                    foreach ($error in $operationResult.errors) {
                        # Access key and value properties directly
                        $errorData += [PSCustomObject]@{
                            Key = $error.key
                            Value = $error.value
                        }
                    }
                }
            }
            
            # Display as table
            if ($errorData.Count -gt 0) {
                $errorData | Format-Table -AutoSize
            }
        }
        throw "User entitlement update failed"
    }

    # Output result
    Write-Host "`n✅ Update completed successfully!" -ForegroundColor Green
    Write-Host "`n📋 Response:" -ForegroundColor Magenta
    $response
}
catch {
    Write-Host "`n❌ " -NoNewline -ForegroundColor Red
    Write-Host "Error occurred: " -NoNewline -ForegroundColor White
    Write-Error $_
    exit 1
}

# Script completed successfully
Write-Host "`n🎉 " -NoNewline -ForegroundColor Green
Write-Host "User entitlement update completed successfully!" -ForegroundColor White
