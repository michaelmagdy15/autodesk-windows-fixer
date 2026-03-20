<#
.SYNOPSIS
    Immersive Autodesk UI Cleaner Script.
.DESCRIPTION
    A full WPF GUI wrapped in PowerShell that automatically elevates to administrator
    and provides a beautiful, responsive visual experience while cleaning Autodesk dependencies.
#>

# 1. Auto-Elevate to Administrator and hide console window
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Restart self as admin
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs -PassThru
    exit
}

# 2. Add WPF Types
Add-Type -AssemblyName PresentationFramework

# 3. Define the XAML with the immersive aesthetic
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Autodesk System Cleaner" Height="650" Width="850"
        WindowStartupLocation="CenterScreen" WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        FontFamily="Segoe UI">
        
    <Window.Resources>
        <Style TargetType="Button" x:Key="ModernButton">
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bgBorder" Background="{TemplateBinding Background}" CornerRadius="12">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="20,15"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bgBorder" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="bgBorder" Property="Opacity" Value="0.7"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="bgBorder" Property="Background" Value="#A0A0A0"/>
                                <Setter Property="Foreground" Value="#E0E0E0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <!-- App Container -->
    <Border CornerRadius="20" Background="White" BorderThickness="1" BorderBrush="#EAEAEA">
        <Border.Effect>
            <DropShadowEffect BlurRadius="30" ShadowDepth="10" Opacity="0.15" Direction="270" Color="Black"/>
        </Border.Effect>
        <Grid>
            
            <!-- IMMERSIVE BACKGROUND PATTERN (Dash grid matching screenshot) -->
            <!-- The Opacity mask reveals the colorful gradient underneath only where the dashes are -->
            <Rectangle RadiusX="15" RadiusY="15">
                <Rectangle.Fill>
                    <LinearGradientBrush StartPoint="0,1" EndPoint="1,0">
                        <GradientStop Color="#4A65E6" Offset="0"/>   <!-- Deep Blue -->
                        <GradientStop Color="#A262BA" Offset="0.3"/> <!-- Purple -->
                        <GradientStop Color="#D1508A" Offset="0.6"/> <!-- Pink -->
                        <GradientStop Color="#E6A140" Offset="1"/>   <!-- Yellow/Orange -->
                    </LinearGradientBrush>
                </Rectangle.Fill>
                <Rectangle.OpacityMask>
                    <!-- Grid of floating dashes -->
                    <DrawingBrush Viewport="0,0,45,45" ViewportUnits="Absolute" TileMode="Tile">
                        <DrawingBrush.Drawing>
                            <DrawingGroup>
                                <GeometryDrawing Brush="White">
                                    <GeometryDrawing.Geometry>
                                        <!-- Angled dash shape -->
                                        <RectangleGeometry Rect="18,18,5,15" RadiusX="2.5" RadiusY="2.5">
                                            <RectangleGeometry.Transform>
                                                <RotateTransform Angle="45" CenterX="20" CenterY="25"/>
                                            </RectangleGeometry.Transform>
                                        </RectangleGeometry>
                                    </GeometryDrawing.Geometry>
                                </GeometryDrawing>
                            </DrawingGroup>
                        </DrawingBrush.Drawing>
                    </DrawingBrush>
                </Rectangle.OpacityMask>
            </Rectangle>

            <!-- GLASSMORPHISM CENTER PANEL -->
            <Border Background="#EBFFFFFF" CornerRadius="18" Margin="60,60,60,60" Padding="40" 
                    BorderBrush="#80FFFFFF" BorderThickness="2">
                <Border.Effect>
                    <DropShadowEffect BlurRadius="40" ShadowDepth="5" Opacity="0.2" Color="Black"/>
                </Border.Effect>

                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <!-- Header -->
                    <StackPanel Grid.Row="0" Margin="0,0,0,25">
                        <TextBlock Text="Autodesk Clean Uninstall" FontSize="36" FontWeight="Black" Foreground="#2A2A2A" HorizontalAlignment="Center"/>
                        <TextBlock Text="Completely removes all traces of Autodesk to fix installation errors." FontSize="15" Foreground="#666666" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>

                    <!-- Hacker-style Terminal / Log Output -->
                    <Border Grid.Row="2" Background="#0C0C0C" CornerRadius="12" Margin="0,0,0,25">
                        <Border.Effect>
                            <DropShadowEffect BlurRadius="5" ShadowDepth="2" Opacity="0.5" Color="Black" Direction="90"/>
                        </Border.Effect>
                        <ScrollViewer x:Name="scrollViewer" Margin="15" VerticalScrollBarVisibility="Auto">
                            <TextBlock x:Name="txtLog" Foreground="#00FF41" FontFamily="Consolas" FontSize="13" TextWrapping="Wrap"/>
                        </ScrollViewer>
                    </Border>

                    <!-- Progress tracking -->
                    <StackPanel Grid.Row="3" Margin="0,0,0,25">
                        <Grid Margin="0,0,0,8">
                            <TextBlock x:Name="txtStatus" Text="Awaiting initialization..." FontSize="14" FontWeight="SemiBold" Foreground="#444444" HorizontalAlignment="Left"/>
                            <TextBlock x:Name="txtPercent" Text="0%" FontSize="14" FontWeight="Bold" Foreground="#444444" HorizontalAlignment="Right"/>
                        </Grid>
                        
                        <!-- Track Container -->
                        <Border Height="14" CornerRadius="7" Background="#E0E0E0">
                            <!-- Animated indicator width managed in codebehind -->
                            <Border x:Name="progressIndicator" Width="0" HorizontalAlignment="Left" CornerRadius="7">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#4A65E6" Offset="0"/>
                                        <GradientStop Color="#D1508A" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                            </Border>
                        </Border>
                    </StackPanel>

                    <!-- Action Buttons -->
                    <Grid Grid.Row="4">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="20"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <Button x:Name="btnExit" Content="CANCEL" Grid.Column="0" Background="#DDDDDD" Foreground="#555555" Style="{StaticResource ModernButton}"/>
                        <Button x:Name="btnStart" Content="START CLEAN" Grid.Column="2" Background="#4A65E6" Style="{StaticResource ModernButton}"/>
                    </Grid>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
"@

# 4. Parse the XAML into a UI Window
Try {
    [xml]$XAMLData = $xaml
    $reader = New-Object System.Xml.XmlNodeReader $XAMLData
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
} Catch {
    Write-Error "Failed to load XAML Interface. The powershell script encountered an error parsing the UI."
    Read-Host "Press enter to exit..."
    exit
}

# 5. Bring in Controls from XAML
$btnStart = $window.FindName("btnStart")
$btnExit = $window.FindName("btnExit")
$txtLog = $window.FindName("txtLog")
$txtStatus = $window.FindName("txtStatus")
$txtPercent = $window.FindName("txtPercent")
$progressIndicator = $window.FindName("progressIndicator")
$scrollViewer = $window.FindName("scrollViewer")

# Default values
$txtLog.Text = "> System Ready.`n> Press 'START CLEAN' to safely remove Autodesk traces..."

# 6. Allow window dragging
$window.add_MouseLeftButtonDown({
    $window.DragMove()
})

# 7. Setup UI responsiveness helpers
function Update-UI {
    $dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $action = [System.Action[System.Windows.Threading.DispatcherFrame]] {
        param($f)
        $f.Continue = $false
    }
    $dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, $action, $frame) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Wait-UI([int]$milliseconds) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.ElapsedMilliseconds -lt $milliseconds) {
        Update-UI
        Start-Sleep -Milliseconds 15
    }
}

# 8. Button Logic (Runs on Main Thread but Pumps Messages to not Freeze)
$btnStart.add_Click({
    $btnStart.IsEnabled = $false
    $btnExit.IsEnabled = $false
    $txtLog.Text += "`n> Executing Cleanup Sequence..."
    $txtStatus.Text = "Starting..."
    Update-UI

    # Local Logging Function
    function LogMsg($msg, [int]$progress) {
        $txtStatus.Text = ($msg -replace "> ", "").Trim()
        $txtLog.Text += "`n" + $msg
        $scrollViewer.ScrollToEnd()
        
        $percent = $progress
        $maxWidth = $progressIndicator.Parent.ActualWidth
        $progressIndicator.Width = ($percent / 100.0) * $maxWidth
        $txtPercent.Text = "$percent%"
        
        Update-UI
    }

    try {
        LogMsg "> Initializing automated cleanup..." 5
        Wait-UI 800

        LogMsg "> Uninstalling Autodesk ODIS (Install Service)..." 8
        $odisUninstaller = "$env:ProgramFiles\Autodesk\AdODIS\V1\RemoveODIS.exe"
        if (Test-Path $odisUninstaller) {
            try {
                $proc = Start-Process -FilePath $odisUninstaller -ArgumentList "--mode silent" -PassThru -NoNewWindow -ErrorAction SilentlyContinue
                if ($proc) { $proc.WaitForExit() }
            } catch {}
            Wait-UI 1500
        }

        LogMsg "> Force stopping Autodesk processes..." 10
        $processesToStop = @("AdAppMgr*", "AdskLicensing*", "AdskIdentityManager*", "AdODIS*", "AutodeskDesktopApp*", "acad", "revit", "maya", "AdskAccessServiceHost*", "RemoveODIS*")
        foreach ($proc in $processesToStop) {
            Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        Wait-UI 500

        LogMsg "> Terminating Autodesk system services..." 20
        $servicesToStop = @("AdskLicensingService", "Autodesk Desktop App Service", "FlexNet Licensing Service", "FlexNet Licensing Service 64", "Autodesk Access Service Host", "AdODISService")
        foreach ($svc in $servicesToStop) {
            $runningSvc = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($runningSvc -and $runningSvc.Status -eq 'Running') {
                LogMsg "  -> Stopped service: $svc" 25
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Wait-UI 200
            }
        }
        Wait-UI 300

        LogMsg "> Purging Autodesk installation directories..." 30
        $directoriesToRemove = @(
            "$env:ProgramFiles\Autodesk",
            "${env:ProgramFiles(x86)}\Autodesk",
            "$env:CommonProgramFiles\Autodesk Shared",
            "${env:CommonProgramFiles(x86)}\Autodesk Shared",
            "$env:ProgramData\Autodesk",
            "$env:LOCALAPPDATA\Autodesk",
            "$env:APPDATA\Autodesk"
        )

        $step = 30.0
        $stepIncr = 40.0 / $directoriesToRemove.Count
        foreach ($dir in $directoriesToRemove) {
            if (Test-Path $dir) {
                LogMsg "  -> Destroyed: $dir" ([int][math]::Round($step))
                cmd.exe /c "rd /s /q `"$dir`"" 2>&1 | Out-Null
            }
            $step += $stepIncr
        }

        LogMsg "> Removing FLEXnet licensing data..." 70
        $flexNetPath = "$env:ProgramData\FLEXnet"
        if (Test-Path $flexNetPath) {
            Remove-Item -Path "$flexNetPath\adskflex_*" -Force -Recurse -ErrorAction SilentlyContinue
        }
        Wait-UI 500

        LogMsg "> Wiping Autodesk registry keys..." 75
        $registryPaths = @(
            "HKLM\SOFTWARE\Autodesk",
            "HKCU\SOFTWARE\Autodesk"
        )

        foreach ($regPath in $registryPaths) {
            LogMsg "  -> Erased key: $regPath" 80
            cmd.exe /c "reg delete `"$regPath`" /f" 2>&1 | Out-Null
        }

        LogMsg "> Unblocking Autodesk installers in registry..." 82
        $ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
        if (Test-Path $ifeoPath) {
            $subKeys = Get-ChildItem -Path $ifeoPath -ErrorAction SilentlyContinue
            foreach ($key in $subKeys) {
                $debugger = Get-ItemProperty -Path $key.PSPath -Name "Debugger" -ErrorAction SilentlyContinue
                if ($debugger -and $debugger.Debugger -match "Blocked") {
                    LogMsg "  -> Unblocked installer: $($key.PSChildName)" 84
                    Remove-ItemProperty -Path $key.PSPath -Name "Debugger" -Force -ErrorAction SilentlyContinue
                }
            }
        }

        LogMsg "> Scanning registry for phantom uninstallers..." 85
        $uninstallPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )

        foreach ($path in $uninstallPaths) {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "Autodesk" -or $_.Publisher -match "Autodesk" }
            foreach ($item in $items) {
                if ($item.DisplayName) {
                    LogMsg "  -> Scrubbed uninstaller: $($item.DisplayName)" 90
                    $regKeyPath = $item.PSPath -replace '^.*::', ''
                    $regKeyPathCmd = $regKeyPath -replace 'HKEY_LOCAL_MACHINE', 'HKLM' -replace 'HKEY_CURRENT_USER', 'HKCU'
                    cmd.exe /c "reg delete `"$regKeyPathCmd`" /f " 2>&1 | Out-Null
                }
            }
        }

        LogMsg "> Clearing temporary system files..." 95
        cmd.exe /c "rd /s /q `"$env:TEMP`"" 2>&1 | Out-Null
        
        Wait-UI 1000
        LogMsg "> Cleanup process fully completed!" 100
        
        $txtStatus.Text = "Success! Please restart your PC."
        $txtStatus.Foreground = "#1A9330"
    } catch {
        LogMsg "> FATAL ERROR: $_" 100
        $txtStatus.Text = "An error occurred."
        $txtStatus.Foreground = "#CC0000"
    }

    $btnExit.Content = "CLOSE"
    $btnExit.IsEnabled = $true
    Update-UI
})

$btnExit.add_Click({
    $window.Close()
})

# 9. Show the UI!
$window.ShowDialog() | Out-Null
