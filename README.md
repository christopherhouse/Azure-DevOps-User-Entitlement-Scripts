# 🎫 Azure DevOps User Entitlements Manager

A PowerShell script to programmatically update user license entitlements in Azure DevOps organizations.

## 📋 Overview

This script allows you to modify user access levels (license types) in Azure DevOps using the REST API. It's perfect for automating user license management, bulk updates, or integrating into larger DevOps workflows.

### ✨ Features

- 🔍 **User Search**: Automatically finds users by email/principal name
- 🎯 **License Management**: Updates user access levels with validation
- 🛡️ **Error Handling**: Comprehensive error reporting with detailed messages
- 🎨 **Rich Output**: Colorful, emoji-enhanced console output for better UX
- 📊 **Status Display**: Shows current and target license information
- 🔐 **Secure Authentication**: Uses Personal Access Tokens (PAT)

## 🚀 Quick Start

### Prerequisites

- PowerShell 5.1 or later
- Azure DevOps organization access
- Personal Access Token with **User Entitlements (Read & Write)** permissions

### Basic Usage

```powershell
.\update-entitlements.ps1 -Organization "myorg" -UserName "user@company.com" -Pat "your-pat-token" -LicenseType "stakeholder"
```

## 📖 Parameters

| Parameter | Type | Required | Description | Valid Values |
|-----------|------|----------|-------------|--------------|
| `Organization` | String | ✅ | Azure DevOps organization name | Any valid org name |
| `UserName` | String | ✅ | User's email or principal name | Valid email address |
| `Pat` | String | ✅ | Personal Access Token | Valid PAT with entitlements permissions |
| `LicenseType` | String | ✅ | Target license type | `stakeholder`, `express`, `advanced`, `earlyAdopter` |

## 🎯 License Types Explained

| License Type | Description | Typical Use Case |
|--------------|-------------|------------------|
| `stakeholder` | Basic access, limited features | View-only users, stakeholders |
| `express` | Standard access | Most team members |
| `advanced` | Full access to premium features | Power users, test managers |
| `earlyAdopter` | Early access to new features | Beta testers, advanced users |

## 💡 Usage Examples

### Update Single User to Stakeholder
```powershell
.\update-entitlements.ps1 -Organization "contoso" -UserName "john.doe@contoso.com" -Pat "abcd1234..." -LicenseType "stakeholder"
```

### Promote User to Advanced License
```powershell
.\update-entitlements.ps1 -Organization "fabrikam" -UserName "jane.smith@fabrikam.com" -Pat "xyz9876..." -LicenseType "advanced"
```

### Bulk Update (using PowerShell pipeline)
```powershell
$users = @("user1@company.com", "user2@company.com", "user3@company.com")
$users | ForEach-Object {
    .\update-entitlements.ps1 -Organization "myorg" -UserName $_ -Pat "your-pat" -LicenseType "express"
}
```

## 🔐 Setting Up Authentication

### 1. Create a Personal Access Token

1. Go to your Azure DevOps organization
2. Click on your profile → **Personal access tokens**
3. Click **+ New Token**
4. Configure the token:
   - **Name**: `Entitlements Management`
   - **Expiration**: Choose appropriate duration
   - **Scopes**: Select **User Entitlements (Read & Write)**
5. Copy the generated token (you won't see it again!)

### 2. Secure Token Storage

For security, consider storing your PAT in:

```powershell
# Windows Credential Manager
$pat = (Get-Credential -UserName "AzDO-PAT" -Message "Enter PAT").GetNetworkCredential().Password

# Environment Variable
$env:AZDO_PAT = "your-pat-here"
.\update-entitlements.ps1 -Organization "myorg" -UserName "user@company.com" -Pat $env:AZDO_PAT -LicenseType "stakeholder"

# Azure Key Vault (for enterprise scenarios)
$pat = Get-AzKeyVaultSecret -VaultName "MyVault" -Name "AzDO-PAT" -AsPlainText
```

## 🔍 Sample Output

### Successful Update
```
🔍 Searching for user: john.doe@contoso.com

✅ Found user: John Doe (john.doe@contoso.com)
🆔 User GUID: d0bf36da-1807-637d-8b32-eaf3c0de9706

📊 Current Access Level:
  🎫 License Type: none
  📝 License Display Name: Visual Studio Enterprise subscription
  📈 Status: active
  🔗 Licensing Source: msdn

🔗 Constructing API URL...
🆔 User ID: d0bf36da-1807-637d-8b32-eaf3c0de9706
🌐 URL: https://vsaex.dev.azure.com/contoso/_apis/userentitlements/d0bf36da-1807-637d-8b32-eaf3c0de9706?api-version=7.1

🚀 Updating user entitlement to: stakeholder

✅ Update completed successfully!

🎉 User entitlement update completed successfully!
```

### Error Handling
```
❌ Update failed!

🔍 Error details:

Key  Value
---  -----
5015 You need to set up billing to assign this access level.
```

## 🛠️ Extending the Script

### Adding New License Types

To add support for new license types, update the `ValidateSet` attribute:

```powershell
[ValidateSet("stakeholder", "express", "advanced", "earlyAdopter", "newLicenseType")]
[string]$LicenseType
```

### Custom Error Handling

Extend error handling for specific scenarios:

```powershell
if ($response.isSuccess -eq $false) {
    # Check for specific error codes
    $billingErrors = $errorData | Where-Object { $_.Key -eq 5015 }
    if ($billingErrors) {
        Write-Host "💳 Billing setup required!" -ForegroundColor Yellow
        # Custom billing setup logic here
    }
}
```

### Integration with CI/CD

Create a wrapper for automated deployments:

```powershell
# pipeline-entitlements.ps1
param($ConfigFile)

$config = Get-Content $ConfigFile | ConvertFrom-Json
foreach ($user in $config.users) {
    .\update-entitlements.ps1 -Organization $config.organization -UserName $user.email -Pat $env:AZDO_PAT -LicenseType $user.licenseType
}
```

## 🔧 Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "User not found" | Incorrect email/username | Verify user exists in organization |
| "Unauthorized" | Invalid PAT | Check PAT permissions and expiration |
| "Billing setup required" | No billing configured | Set up billing in Azure DevOps |
| "Invalid license type" | Unsupported license | Use valid license types only |

### Debug Mode

Run with verbose output:

```powershell
.\update-entitlements.ps1 -Organization "myorg" -UserName "user@company.com" -Pat "pat" -LicenseType "stakeholder" -Verbose
```

## 📚 API Reference

This script uses the [Azure DevOps User Entitlements REST API](https://docs.microsoft.com/en-us/rest/api/azure/devops/memberentitlementmanagement/user-entitlements?view=azure-devops-rest-7.1):

- **GET** `/userentitlements` - Search for users
- **PATCH** `/userentitlements/{userId}` - Update user entitlements

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

### Development Setup

1. Clone the repository
2. Test with your Azure DevOps organization
3. Submit PRs with clear descriptions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Azure DevOps API documentation
3. Open an issue with detailed error information

---

⭐ **Star this repository** if you find it helpful!
