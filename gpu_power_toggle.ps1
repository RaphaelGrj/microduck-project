# Bascule la consommation du GPU (RTX 5070 Ti) entre "normal/jeu" et "economie
# training RL". Double-cliquer ce script (ou le raccourci bureau "GPU Power
# Toggle") pour basculer dans l'autre sens.
#
# Deux leviers combines :
#   - nvidia-smi -pl : limite de puissance. Plancher materiel de cette carte =
#     250 W (verifie le 2026-10-15, nvidia-smi --query-gpu=power.min_limit) ;
#     impossible de descendre plus bas par ce biais.
#   - nvidia-smi -lgc : bride la frequence graphique max. Pas de plancher a
#     250 W ici, c'est le vrai levier pour baisser sous la conso deja mesuree
#     (~133 W pendant un training, donc sous le plancher -pl). Mecanisme
#     officiel NVIDIA : ne fait que restreindre la frequence dans la plage
#     validee par le vBIOS, jamais de survoltage -> sans risque pour la carte
#     (contrairement a un undervolt manuel type MSI Afterburner).
#
# ECONOMIE_CLOCK_MHZ : valeur prudente, A VALIDER A LA MAIN avant de la
# changer (stabilite + gain reel mesure avec nvidia-smi --query-gpu=power.draw
# pendant un training) plutot que de l'augmenter a l'aveugle.
$EconomieClockMHz = 1800

# nvidia-smi -pl exige des droits administrateur : ce script s'auto-eleve (une
# fenetre UAC a confirmer a chaque clic) plutot que de dependre de taches
# planifiees (abandonne : le declenchement sans elevation etait bloque par
# Windows malgre la tache /ru SYSTEM).

$current = (nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits).Trim()
$currentW = [double]$current
$toEconomie = $currentW -gt 275

if ($toEconomie) {
    $cmd = "-i 0 -pl 250 && nvidia-smi -i 0 -lgc $EconomieClockMHz,$EconomieClockMHz"
    $label = "Mode economie active (250 W, horloge bridee a $EconomieClockMHz MHz)"
} else {
    $cmd = "-i 0 -pl 300 && nvidia-smi -i 0 -rgc"
    $label = "Mode normal / jeu active (300 W, horloge libre)"
}

Start-Process -FilePath "cmd.exe" -ArgumentList "/c nvidia-smi $cmd" -Verb RunAs -Wait

Start-Sleep -Milliseconds 500
$newLimit = (nvidia-smi --query-gpu=power.limit --format=csv,noheader,nounits).Trim()
$newClock = (nvidia-smi --query-gpu=clocks.max.graphics --format=csv,noheader,nounits).Trim()

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("$label`n`nLimite GPU actuelle : $newLimit W`nHorloge max actuelle : $newClock MHz", "GPU Power Toggle", "OK", "Information") | Out-Null
