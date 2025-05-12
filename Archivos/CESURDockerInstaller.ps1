# Comprobar si el script se ejecuta con privilegios de administrador
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

# Definir el nombre del grupo
$groupName = "docker-users"

# Obtener el nombre del usuario actual
$currentUser = "$env:COMPUTERNAME\$env:USERNAME"

# Instalador Docker
$installerUri = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$installerPath = "DockerDesktopInstaller.exe"

Write-Host "Usuario requerido para la instalación:"
Write-Host "admlocal.malagaeste.01@cesurformacion.com"

if (-not $principal.IsInRole($adminRole)) {
    Write-Host "Este script requiere privilegios de administrador. Reiniciando con permisos elevados..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs

    Write-Host "Preparando la descarga..."

    try {
        Write-Host "Iniciando descarga de Docker Desktop..."

        & "$env:SystemRoot\System32\curl.exe" -L -# -o $installerPath $installerUri

        #Invoke-WebRequest -Uri $installerUri -OutFile $installerPath
        Write-Host "Descarga completada."
    } catch {
        Write-Error "Error al descargar Docker Desktop con curl.exe: $_"
        Write-Host "Intentando descarga directa..."
        Invoke-WebRequest -Uri $installerUri -OutFile $installerPath
        Write-Host "Descarga completada."
    }

    # Comprobar si el grupo ya existe
    if (-not (Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue)) {
        # Crear el grupo local
        New-LocalGroup -Name $groupName -Description "Grupo de prueba"
        Write-Host "Grupo '$groupName' creado correctamente."
    } else {
        Write-Host "El grupo '$groupName' ya existe."
    }

    # Añadir el usuario actual al grupo
    Add-LocalGroupMember -Group $groupName -Member $currentUser
    Write-Host "Usuario '$currentUser' añadido al grupo '$groupName'."

    # Ejecutar Docker Desktop Installer.exe
    if (Test-Path $installerPath) {
        Start-Process -FilePath $installerPath -Wait -ArgumentList 'install', '--accept-license'
        Write-Host "Ejecutando Docker Desktop Installer..."
    } else {
        Write-Host "El instalador de Docker Desktop no se encontró en la ruta especificada."
    }

    exit
} 