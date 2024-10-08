[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]$commitMsgFile
)

$minimumAfterMessageLength = 3
$jiraProjectName = "TEST" # Set your Ticketing system project name here
$commitMessage = [string](Get-Content $commitMsgFile)
$allowedCategories = @("Backend","Frontend","Pipeline","Infra","Docs", "E2E")
$categoriesForErrorMessage = $allowedCategories -join '|'
$allowedKeywords = @("Add","Update","Remove","Refactor","Rename","Move","Fix")
$keywordsForErrorMessage = $allowedKeywords -join '|'
$passReturnCode = 0
$failReturnCode = 1

$errorMessage = "Commit message format has to follow either '$jiraProjectName-1234: <Keyword> something' or '<Category>: <Keyword> something'" + `
"`nAllowed keywords: $keywordsForErrorMessage" + `
"`nAllowed categories: $categoriesForErrorMessage" + `
"`nExample: $jiraProjectName-1234: Add foo to enable bar" + `
"`nExample: Pipeline: Fix build errors in CI"

Write-Verbose "--Start of commit hook script--"
Write-Verbose "--Start of commit parameters--"
Write-Verbose "Commit message file path: $commitMsgFile"
Write-Verbose "Commit message file contents: $commitMessage"
Write-Verbose "--End of commit parameters--"

if($commitMessage.StartsWith("Merge branch")) {
    Write-Verbose "Pass based on merge branch"
    exit $passReturnCode
}

if(-not $commitMessage.Contains(":")) {
    Write-Host "Missing delimeter character ':' in commit message: '$commitMessage'.`n$errorMessage" -ForegroundColor Red
    exit $failReturnCode
}

$firstDelimeterIndex = $commitMessage.IndexOf(":")
$category = $commitMessage.Split(":")[0]
$afterMessage = $commitMessage.Substring($firstDelimeterIndex + 1)
Write-Verbose "Category: $category"
Write-Verbose "Post message: $afterMessage"

function CheckStartOfTheMessageForAllowedKeywords {
    if($afterMessage.Length -le $minimumAfterMessageLength) {
        $lengthWas = $afterMessage.Length
        Write-Host "Description is too short: $afterMessage ($lengthWas characters). Use more than $minimumAfterMessageLength characters.`n$errorMessage" -ForegroundColor Red
        exit $failReturnCode
    }
    $matchKeywordsArray = $allowedKeywords | ForEach-Object { if($afterMessage.StartsWith(" " + $_ + " ")) { $True } }
    if(-not( $matchKeywordsArray -match $True)) {
        Write-Host "Commit message may not start with '$afterMessage'.`n$errorMessage." -ForegroundColor Red
        exit $failReturnCode
    }
}

# match to "JIRAPROJECTID-<nnn>: <Keyword> something" syntax
if($commitMessage -match "^$jiraProjectName-\d+:") {
    Write-Verbose "Found regex match"
    CheckStartOfTheMessageForAllowedKeywords
    Write-Verbose "Pass based on '$jiraProjectName-<n>: <Keyword> something'."
    exit $passReturnCode
}

# match to "<Category>: <Keyword> something" syntax
$matchCategoriesArray = $allowedCategories | ForEach-Object { if($commitMessage.StartsWith($_)) { $True } }
if($matchCategoriesArray -match $True) {
    Write-Verbose "Found category match"
    CheckStartOfTheMessageForAllowedKeywords
    Write-Verbose "Pass based on '<Category>: <Keyword> something'."
    exit $passReturnCode
}

Write-Host $errorMessage -ForegroundColor Red
# By default reject
exit $failReturnCode
