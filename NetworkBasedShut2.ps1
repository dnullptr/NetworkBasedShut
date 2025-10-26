Add-Type -AssemblyName System.Windows.Forms

# GUI for adapter selection
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select Network Adapter"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(20,20)
$comboBox.Size = New-Object System.Drawing.Size(340,20)
Get-NetAdapter | ForEach-Object { $comboBox.Items.Add($_.Name) }
$form.Controls.Add($comboBox)

$label = New-Object System.Windows.Forms.Label
$label.Text = "Grace seconds before shutdown:"
$label.Location = New-Object System.Drawing.Point(20,60)
$form.Controls.Add($label)

$graceInput = New-Object System.Windows.Forms.TextBox
$graceInput.Location = New-Object System.Drawing.Point(250,60)
$graceInput.Size = New-Object System.Drawing.Size(50,20)
$graceInput.Text = "60"
$form.Controls.Add($graceInput)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(150,100)
$form.Controls.Add($okButton)

$adapterName = $null
$graceLimit = 60
$okButton.Add_Click({
    if ($comboBox.SelectedItem) {
        $script:adapterName = $comboBox.SelectedItem.ToString()
        $script:graceLimit = [int]$graceInput.Text
        $form.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select an adapter.")
    }
})

$form.ShowDialog()

if (-not $adapterName) {
    Write-Host "No adapter selected. Exiting."
    exit
}

try {
    $null = Get-NetAdapterStatistics -Name $adapterName
} catch {
    [System.Windows.Forms.MessageBox]::Show("Adapter '$adapterName' not found or inaccessible.")
    exit
}

# Threshold in KB/s
$thresholdKBps = 50
$lowTrafficCount = 0

function Get-BytesTransferred {
    try {
        $stats = Get-NetAdapterStatistics -Name $adapterName
        return $stats.ReceivedBytes + $stats.SentBytes
    } catch {
        Write-Host "Error retrieving adapter stats."
        return 0
    }
}

$prevBytes = Get-BytesTransferred

while ($true) {
    Start-Sleep -Seconds 1
    $currBytes = Get-BytesTransferred
    $diffKB = ($currBytes - $prevBytes) / 1KB
    Write-Host "Transfer Rate: $diffKB KB/s"

    if ($diffKB -lt $thresholdKBps) {
        $lowTrafficCount++
        Write-Host "Low traffic count: $lowTrafficCount / $graceLimit"
        if ($lowTrafficCount -ge $graceLimit) {
            Write-Host "Triggering shutdown in 60 seconds..."
            Start-Process "shutdown.exe" -ArgumentList "/s /t 60"
            break
        }
    } else {
        $lowTrafficCount = 0
    }

    $prevBytes = $currBytes
}
