
$adapterName = "Marvell AQtion 10Gbit Network Adapter"

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

function Show-Message($msg, $title = "TX401 Config Tool") {
    [System.Windows.Forms.MessageBox]::Show($msg, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

try {
    $adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*AQtion*" }

    if (!$adapter) {
        Show-Message "❌ Aucun adaptateur Marvell AQtion détecté."
        exit
    }

    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
    $log = @()
    $found = $false

    Get-ChildItem $registryPath | ForEach-Object {
        $key = $_.PSPath
        try {
            $driverDesc = Get-ItemPropertyValue -Path $key -Name "DriverDesc" -ErrorAction Stop
            if ($driverDesc -like "*AQtion*") {
                $found = $true
                Set-ItemProperty -Path $key -Name "EEELinkAdvertisement" -Value 0 -Force
                Set-ItemProperty -Path $key -Name "EnableWakeOnMagicPacket" -Value 1 -Force
                Set-ItemProperty -Path $key -Name "EnableShutdownWake" -Value 1 -Force
                Set-ItemProperty -Path $key -Name "*ReceiveBuffers" -Value 512 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $key -Name "*TransmitBuffers" -Value 2048 -ErrorAction SilentlyContinue

                $log += "✅ Paramètres appliqués à : $driverDesc"
                $log += " - EEE = Disabled"
                $log += " - Wake on Magic Packet = Enabled"
                $log += " - Shutdown WoL = Enabled"
                $log += " - Buffers Rx/Tx = 512 / 2048"

                Restart-NetAdapter -Name $adapter.Name -Confirm:$false
                $log += "🔁 Carte redémarrée : $($adapter.Name)"
            }
        } catch {}
    }

    if ($found) {
        $logPath = "$env:USERPROFILE\Desktop\TX401_config_log.txt"
        $log | Out-File -FilePath $logPath -Encoding UTF8
        Show-Message "✅ Configuration appliquée avec succès. Voir log : TX401_config_log.txt sur le Bureau."
    } else {
        Show-Message "❌ Impossible de localiser la carte dans le registre."
    }
} catch {
    Show-Message "❌ Erreur inattendue : $_"
}
