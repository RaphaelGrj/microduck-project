# Projet Microduck — contexte

## Statut
Robot Microduck (Pollen Robotics) commandé avec pack incluant 2 batteries
supplémentaires, pas encore livré (délai annoncé 4-6 mois depuis fin août 2026).
Tout le travail actuel se fait en simulation/préparation, sans robot physique.

## Objectif général
En faire un vrai membre du foyer façon droïde Star Wars : présence
autonome, personnalité cohérente, interaction physique et vocale — pas
un simple gadget de démo.

## Deux projets prioritaires

### 1. Jeu de balle interactif
Le comportement officiel `BallKick` est "aveugle" : il tape dans un
ballon à position fixe simulée, sans jamais le voir. Objectif : une
politique qui utilise vraiment la caméra pour repérer le ballon et
réagir à sa position réelle, pour un vrai jeu avec moi plutôt qu'un
mouvement scripté.
Référence utile : projet communautaire `laya-vision-microduck-kick`
(vision-langage-action). S'inspirer de sa structure plutôt que
repartir de zéro.

### 2. Intégration Home Assistant
Je veux que le robot puisse déclencher des scènes domotiques et
remonter des informations. Point de départ : le projet communautaire
`quacksat` (pont vocal via protocole Wyoming). Objectif à terme :
aller au-delà du simple vocal pour remonter des états du robot
(batterie, position) comme entités Home Assistant, via l'API réseau
exposée par `robotd`.
Idée de départ concrète : notifications d'impression 3D (j'ai deux
Ender 3 V2 sous Klipper/Moonraker) — le robot réagit vocalement à la
fin ou à l'échec d'une impression.

## Idées explorées, à garder en tête pour plus tard
- Tags NFC posés dans la maison (une antenne dans le bec, une dans la
  tête) comme déclencheurs physiques de scènes HA, ou identification
  d'objets ramassés.
- Localisation intérieure par balises UWB (type DWM1001-DEV) : ancres
  fixes dans la maison, une définie comme origine (0,0,0), pour donner
  au robot des coordonnées réelles et naviguer vers un point nommé.
- Sac à dos externe ESP32 (BLE) pour capteurs additionnels, communiquant
  avec un PC/serveur qui orchestre à la fois ce flux et la télémétrie
  du robot plutôt qu'une liaison directe ESP32 ↔ robot.
- Système de personnalité/état d'émotion transverse (son + mouvement +
  réactions cohérents), dans l'esprit de mon projet perso Lumi
  (ESP32 + Gemini + écran expressif), mais sans écran pour rester
  fidèle à l'identité sonore du Microduck (pas d'anthropomorphisme
  visuel).

## Repères techniques déjà connus
- Stack officielle 100% ouverte (Apache-2.0) : `pollen-robotics/microduck`
  (runtime Rust embarqué, daemons `robotd`/`updaterd`/`mediad`/`tofd`/...)
  et `pollen-robotics/microduck_rl` (entraînement RL, mjlab + PPO,
  export ONNX).
- Contrat d'observation partagé entre toutes les politiques officielles :
  61 dimensions en entrée (proprioception + commandes), 14 en sortie.
- Entraînement possible en local (GPU CUDA requis) ou via
  `--hf-jobs` (Hugging Face Jobs, pas de GPU local nécessaire).
- Microduck Academy (Hugging Face) : décrire un comportement en langage
  naturel, entraînement/remix géré côté HF.
- Catalogue de politiques communautaires centralisé sur `uduck-registry`.
- Matériel non ouvert (pas de GPIO exposé documenté) — toute extension
  matérielle externe passe par le réseau (Wi-Fi/BT), pas par du filaire.

## Environnement de dev
- Windows 11, GPU NVIDIA RTX 5070 Ti (driver CUDA 13.2 au 2026-09-30) — entraînement local possible.
- Approche choisie : WSL2 (Ubuntu 26.04 LTS) + dépôt officiel `pollen-robotics/microduck_rl`
  cloné directement dedans (plutôt que le wrapper communautaire `maxy_duck`), pour rester à
  jour avec l'amont.
- Pas de driver NVIDIA séparé à installer dans WSL : le driver Windows fournit le passthrough
  CUDA nativement (confirmé via `nvidia-smi` dans WSL).
- Le clone de `microduck_rl` vit dans le filesystem WSL natif (`~/microduck_rl` = 
  `\\wsl.localhost\Ubuntu\home\raphael\microduck_rl`), **pas** sous `D:\Projet\MICRODUCK`
  directement : le montage 9p de `D:\` dans WSL ne supporte pas `chmod` (pas d'option
  `metadata` dans `/etc/wsl.conf`), ce qui casse `git clone`/`uv sync`. Un raccourci Windows
  `microduck_rl (WSL).lnk` est présent dans ce dossier pour y accéder depuis l'Explorateur/VS
  Code. Si besoin d'activer l'accès natif en écriture depuis Windows plus tard, ajouter
  `options = "metadata"` sous `[automount]` dans `/etc/wsl.conf` (sudo requis) puis
  `wsl --shutdown`.

## Mon niveau
CNC (Haas TM-2P, filetage NPT), impression 3D (prusa mk3s),
Blender, développement web. Déjà familier avec ESP32/Python/Rust à un
niveau hobbyiste (projets Lumi et rover).
