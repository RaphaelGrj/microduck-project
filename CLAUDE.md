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
Prusa MK3S qui sera upgrade en MK4S donc Prusa connect + Elegoo Saturn 4 Ultra) — le robot réagit vocalement à la
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
- Microduck doit à terme, être un membre actif et autonome du foyer.  

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

## État d'avancement (2026-09-30)
- Premier entraînement local validé de bout en bout : `Mjlab-Velocity-Flat-MicroDuck`,
  4096 environnements, logger `tensorboard` (pas `wandb`, compte jugé "pro" par l'utilisateur).
  **Mis en pause à l'itération 2000** (checkpoint `model_2000.pt` sauvegardé), pour reprendre
  plus tard avec :
  ```
  cd ~/microduck_rl
  uv run train Mjlab-Velocity-Flat-MicroDuck --env.scene.num-envs 4096 --agent.logger tensorboard \
      --agent.resume True --agent.load-run 2026-09-30_19-08-35_velocity
  ```
- Visualisation : `uv run play <TASK> --checkpoint-file <path> --viewer viser` ouvre un viewer
  web (http://localhost:8080, forward WSL→Windows automatique). Script `watch_viewer.sh`
  (dans `microduck_rl`, notre fork) surveille le dossier de logs et relance automatiquement
  le viewer sur chaque nouveau checkpoint (`save-interval` par défaut = 250 itérations).
- Repos GitHub créés : fork `RaphaelGrj/microduck_rl` (remote `origin`, `upstream` = officiel)
  et `RaphaelGrj/microduck-project` (ce dossier, contient ce CLAUDE.md).
- Setup multi-machine en cours : une session Claude Code tourne aussi sur un laptop Linux
  (clone de ces deux repos dans `/mnt/mmc-SN128_0x5c36c07b-part1/microduck/`), pensée pour
  soumettre des trainings via `--hf-jobs` (pas de GPU sur ce laptop). Cette session Linux a
  généré `pc-windows_ssh.ps1` (à la racine de ce repo) pour ouvrir un accès SSH entrant sur
  ce PC Windows (RTX 5070 Ti) depuis le laptop — **script non exécuté pour l'instant**, en
  attente de décision. Il ne contient qu'une clé publique, rien de sensible.

## IPC `robotd` — inventaire pour le futur cerveau (lu dans la doc officielle, 2026-10-01)

Transport : socket Unix, JSON-RPC 2.0 / NDJSON (`/run/robotd.sock` sur un vrai
robot ; `~/.cache/duck-sim/duck-a.sock` sous `duck-sim`). Aussi joignable à
distance via `mediad` (WebRTC) et `btd` (BLE, sous-ensemble) — donc le même
cerveau pourra parler à un robot réel, simulé, ou distant sans changer de code.

**Intents continus** (notifications, sans réponse, dernier écrit gagne) :
- `robot.move {vx, vy, vyaw}` — vitesse
- `robot.head {neck_pitch, head_pitch, head_yaw, head_roll}` — regard/tête
  (équivalent réseau de notre `head_offset` scripté)

**Intents discrets** (requêtes, réponse attendue) :
- `robot.stop`
- `robot.enable {on}` — bring-up (Limp → Homing → Ready)
- `robot.init` / `robot.relax` — lever / relâcher (namespace maintenance)
- `robot.do {name}` — déclenche une politique publiée par son nom (ex. le
  nôtre : `uv run publish --name velocity-test ...` → `robot.do
  {"name":"velocity-test"}`). Une seule requête, pas du teleop — pas besoin
  de lien de contrôle actif.
- `robot.skills` — liste les skills chargés ; `robot.setSkill` — lie un skill
  à un slot
- `robot.sound` — jouer un son (la voix du canard)
- Gestion du catalogue : `robot.policies`, `policy.check`, `policy.search`,
  `policy.fetch`, `policy.install`, `robot.loadPolicy`, `robot.reloadPolicies`
  — équivalent RPC de `robotctl policy *`

**État** (flux `robot.subscribe`, décimé par abonné côté serveur) :
- `robot.state` : `{t, t_ns, move:{requested,applied,limited_by}, policy
  (nom du réseau actif ce tick), safety:{fallen,limp}, loop:{hz,missed},
  battery:{volts,percent}, odom:{position,yaw}}`
- `robot.health` — santé de la boucle + batterie/température/bus/IMU
- `robot.model` — géométrie statique (hauteur tronc, ordre des joints,
  directions ToF)

**CLI équivalente** (pour scripter/tester sans écrire de client) :
`robotctl policy list/check/load/update/reset/search`, `robotctl monitor`
(état + carte d'odométrie), `robotctl health`.

**À retenir pour l'architecture du futur cerveau :**
- `init`/calibration/écriture joint brute = namespace **maintenance séparé**,
  jamais exposé sur BLE/WebRTC (sécurité) — seuls `robot.do`, `policies.*`
  et le teleop le sont.
- `look` (regard dédié, au-delà de `head_pose`) est **différé**, pas encore
  implémenté côté officiel.
- `robot.do` est exactement le point d'entrée pour nos futurs gestes
  scriptés/entraînés une fois publiés sur le Hub — pas besoin de
  réimplémenter le déclenchement, juste publier avec le bon `--name`.

## Mon niveau
CNC (Haas TM-2P, filetage NPT), impression 3D (Klipper & Prusa MK3S), Blender, Solidworks, développement web. Familier avec ESP32/Python/Rust en hobbyiste (projets Lumi et rover). Travaille actuellement sous Windows, avec Claude Code installé pour ce projet.
