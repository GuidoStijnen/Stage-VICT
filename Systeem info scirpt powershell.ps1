# Maak een map voor de output
$outputDir = "C:\ServerInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $outputDir

# Pad naar het outputbestand
$outputFile = "$outputDir\ServerInfo_Volledig.txt"

# Functie om informatie toe te voegen aan het bestand
function Add-SectionToFile {
    param([string]$SectionTitle, [scriptblock]$ContentBlock)
    
    "`n`n### $SectionTitle ###" | Out-File -Append -FilePath $outputFile
    "-" * 50 | Out-File -Append -FilePath $outputFile
    & $ContentBlock | Out-File -Append -FilePath $outputFile
}

# Verzamel alle informatie
Add-SectionToFile "Systeem Informatie" { systeminfo }

Add-SectionToFile "OS Naam en Versie" { 
    systeminfo | findstr /B /C:"OS Name" /C:"OS Version" 
}

Add-SectionToFile "Geïnstalleerde Rollen en Functies" { 
    Get-WindowsFeature | Where-Object Installed -eq $true 
}

Add-SectionToFile "Netwerkconfiguratie" { 
    "`nIPConfig All:" 
    ipconfig /all
    "`nGedetailleerde IP Adressen:" 
    Get-NetIPAddress 
}

Add-SectionToFile "Geïnstalleerde Software" { 
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Select-Object DisplayName, DisplayVersion | 
        Where-Object { $_.DisplayName -ne $null } 
}

Add-SectionToFile "Actieve Services" { 
    Get-Service | Where-Object Status -eq 'Running' 
}

Add-SectionToFile "Top Processen (CPU Usage)" { 
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | 
        Format-Table Name, CPU, Id 
}

Add-SectionToFile "Opstartprogramma's" { 
    Get-CimInstance Win32_StartupCommand | 
        Select-Object Name, Command 
}

# Toon locatie van verzamelde informatie
Write-Host "Serverinformatie is verzameld in: $outputFile"
Invoke-Item $outputDir