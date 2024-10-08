Write-Host "Configuring Git hooks path.."
git config core.hooksPath .githooks
Write-Host "Configuring Git hooks path done."

# Macs might have problems on giving execute rights on bash scripts in githooks
if($IsMacOS -or $IsLinux) {
	Write-Host "Configuring execute rights for githooks.."
    chmod +x ./.githooks/commit-msg
	Write-Host "Configuring execute rights for githooks done."
}
