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

## État d'avancement (2026-10-01)
- `VelStand-Rough-Backlash` abandonné (distillation depuis un checkpoint privé Pollen sur
  wandb, 403 Forbidden). Remplacé par `Mjlab-StandUp-Rough-Backlash-MicroDuck` (PPO pur,
  pas de distillation) : c'est le cœur du "se relever après être tombé" visé.
  **Mis en pause à l'itération 2000** (`model_2000.pt`, 21:38). Reprise :
  ```
  cd ~/microduck_rl
  uv run train Mjlab-StandUp-Rough-Backlash-MicroDuck --env.scene.num-envs 4096 \
      --agent.logger tensorboard --agent.resume True \
      --agent.load-run 2026-10-01_18-53-15_microduck_stand
  ```
- `duck-sim` opérationnel (vrais daemons contre un MuJoCo duck), validé via `robot.do` et
  `robot.move`. **Caméra opérationnelle (2026-10-03)** : `webrtcsink` compilé depuis les sources
  (`gst-plugins-rs` **0.15.4**, la 0.14.5 échoue avec GStreamer 1.28), encodeur NVENC déclassé ;
  vidéo 30 FPS dans la console `http://127.0.0.1:8080`. Lancement et pièges :
  `microduck-brain/scripts-wsl/README.md`. Voir section IPC ci-dessous.
- Repo [`RaphaelGrj/microduck-brain`](https://github.com/RaphaelGrj/microduck-brain) créé
  (Phase 3, futur cerveau) — premier script `poc_robotd_client.py` validé contre `duck-sim`.
- Gestes scriptés sans entraînement ajoutés à `infer_policy.py` (notre fork) : **N** = Non
  (yaw), **M** = Oui (pitch), **C** = Curieux (pitch+roll tenu) — `head_offset` piloté dans
  le temps, aucune politique RL nécessaire.
- Patch 6 ajouté à `mdp.py` (notre fork) : corrige un crash du viewer `viser` sur toute tâche
  à commande de vitesse quasi nulle (StandUp, Roulade, SitStand...).

## État d'avancement (2026-10-03, soir)
- **Phase 2 faite** (voir ROADMAP) : approche + tir validés en arène (19/20), visée de la direction du tir (11/12 dans ±35°),
  détecteur de chat YOLOv8n validé sur 4 photos réelles et sur une affiche dans la simulation (`arena_chat`).
  Limite connue : fenêtre de tir étroite (kick à réentraîner avec DR large, GPU) ; appartement non concluant (balle posée
  dans un mur par le banc d'essai ; camouflage de la balle orange sur le tapis rouge du salon).
- **Home Assistant** : pont `pont_ha.py` + faux HA + tests (`microduck-brain`), config locale `ha.toml` (ignorée par git, jeton
  dedans, **jamais sur GitHub**). HA OS tourne sur un **Raspberry Pi 3B+** ; seuls des Pi 3B+ en stock : pont + cerveau
  mesurés à 29 Mo / < 1 % CPU, donc OK sur un Pi 3B+ (installation **non faite**, `deploy/pi/` préparé non testé).
  YOLO/vision ne tournent pas sur un Pi 3B+ (le robot a un NPU : à étudier à sa livraison).
- **Entraînement StandUp** arrêté à 10 000 (2026-10-04, dossier `logs/rsl_rl/microduck_stand/2026-10-04_10-49-32_microduck_stand`).
  Évalué : identique à 7 000 (≈100 % relevé avec poussées) ; robotd se relève déjà seul (`limp_fall`) → plus de GPU pour StandUp.
  Piège : `--agent.resume` écrit dans un NOUVEAU dossier de logs (surveiller le bon dossier).
- Photos du chat dans `microduck-brain/photos_chat/` et modèle dans `modeles/` : **ignorés par git** (dépôt public).

## État d'avancement (2026-10-04, soir)
- **Tir tolérant** (fork : `Mjlab-BallKickTolerant-Flat-Backlash-MicroDuck-Right/Left`, balle 8–15 cm) : droit fini
  (`model_2999.pt` — le dernier checkpoint d'un run de 3000 est 2999), 26/36 au balayage vs 14/36 officiel, pas de gain en
  appartement → `approach.py` profil `officiel` par défaut (`MICRODUCK_TIR`). **Gauche arrêté à 1 750** ; reprise et passe
  douce (`Mjlab-BallKickPasse-*`, 0,5 m/s, accord donné) : `~/kick_reprise.txt`. Banc : `~/kick_tol_eval.sh`, `~/bilan_kick.py`.
- **Jeu avec un joueur** : `microduck-brain/jeu.py` (+ `jeu_eval.py`, scène `arena_chat`) : 3/8 avec l'affiche du chat.
- **Home Assistant réel connecté** (HA 2026.8.3) ; `ha.toml` rempli. MQTT discovery codé (attend Mosquitto).
- **Sécurité** : `robotd` n'a pas de protection anti-chute ; `tof.py` détecte les vides, la promenade marche tête à 0,3 rad.
- `robot.pose` (roulis/tangage du corps debout) et `robot.mouth` existent (geste « content » sans RL).
- Cohabitation **quacksat / quacknav** : `microduck-brain/QUACKSAT_QUACKNAV.md`.
- Pièges : `pgrep/pkill -f` se reconnaît lui-même si le motif est dans sa propre ligne de commande ; l'outil d'édition
  fait perdre le bit exécutable d'un script WSL.

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
- `robot.do {"skill": "<name>"}` — déclenche une politique par son nom
  (champ **`skill`**, pas `name` — vérifié par test réel contre `duck-sim`,
  2026-10-01 ; la doc suggérait `name`, le câblage réel dit `skill`). Une
  seule requête, pas du teleop. Testé avec succès : `{"skill":"roulade"}`.
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
- **Correction (2026-10-03)** : `look` N'EST PAS différé — `robotctl robot look
  <X> <Y> <Z>` existe (pointe la caméra vers un point du repère tronc, en m :
  X avant, Y gauche, Z haut ; le daemon fait la cinématique inverse). C'est la
  brique pour suivre le chat / la balle des yeux (Phase 2). Skills acceptés par
  `robot do` : `roulade`, `kick_left`, `ground_pick`, **`sit_toggle`**
  (s'asseoir / se relever, vérifié : `policy=sit`, tronc à 0.06 m, puis `stand`).
- **`robot.head` = décalages** (0 = neutre), pas des angles absolus ; la tête suit
  (0.6 demandé → joint à 0.57). Les trames d'état arrivent à 50 Hz : un client doit
  se **cadencer sur ce flux** (lire une trame, puis envoyer) sinon il lit des trames
  périmées en attente dans la socket. L'état contient `head`, `joints` (15, tête =
  indices 5..8), `frames.camera/tof/head_imu`, `odom`, `safety`.
- Lancer `duck-sim` : `scripts/duck-sim down` appelle `sudo systemctl` et se bloque
  sans mot de passe en cache → utiliser `~/start-duck.sh` (shim `sudo -n`,
  headless via `DUCK_SIM_VIEWER=0`). Détails et pièges : `microduck-brain/scripts-wsl/README.md`.
  Par défaut : scène appartement + **balle orange de test à 40 cm** (`scene_apartment_testball.xml`,
  fork), caméra à 10 images/s en rendu simplifié (sinon la sim tombe à 0,36× le temps réel :
  rendu OpenGL logiciel sous WSL2, 142 ms/image avec ombres ; options `DUCK_SIM_CAMERA_FLAT`,
  `DUCK_SIM_CAMERA_FPS` dans le fork). Vérifier `scripts/duck-sim realtime` ≥ 1,00×.
- **Zone morte de la marche** (`microduck-brain/ZONE_MORTE.md`) : `alpha_walking` ne fait
  aucune démarche sous ~0,25 m/s avant / ~0,35 arrière / ~1,0 rad/s de rotation, même si
  `policy=walk` et commande appliquée. Utiliser `vx ≥ 0,3`, `|vyaw| ≥ 1,2` ; aligner finement
  avec la **tête**, pas avec le corps. `scripts/duck-sim drive` (0,15 m/s) ne fait donc pas marcher.
- **Perception** (`microduck-brain/vision.py`, `track.py`, `geometry.py`) : image caméra = `GET
  http://127.0.0.1:8080/frame` (PNG portrait 360×640, champ horizontal ~45°, focale ~435 px) ;
  détection de balle par couleur HSV ; suivi du regard calibré automatiquement (< 2 px d'erreur).
  **Position 3D de la balle** : pose de la caméra dans le repère du tronc =
  `robot.state.frames.camera` (pos + quat w,x,y,z, convention caméra x droite / y bas / z devant,
  tronc x avant / y gauche / z haut) ; intersection du rayon pixel avec le sol (z = 3,5 cm −
  hauteur du tronc `odom.position[2]`) ou profondeur par le rayon apparent (R = 3,5 cm) :
  **0,5–2 cm d'erreur de 11 cm à 1 m** (`vis_range.py`, `vis_near.py`). Piège : les pieds orange
  du canard apparaissent au bord bas de l'image quand la tête est baissée à fond (faux positif).
  Environnement : `uv` dans `microduck-brain` (`bash ~/run-brain.sh <script.py>`).
- **Outils de test du simulateur (fork uniquement, sans équivalent sur le vrai robot)** :
  `DUCK_SIM_GROUNDTRUTH` (poses réelles canard + balle dans `~/.cache/duck-sim/groundtruth.json`,
  toutes les 0,1 s) et `DUCK_SIM_CONTROL` (téléporter la balle ou le canard : `truth.py`
  `teleport`, `teleport_duck`) — pour MESURER, jamais pour décider. Scène **`arena`**
  (`bash ~/run-scene.sh arena` : sol plan sans murs + balle d'entraînement exacte) : l'appartement
  est inutilisable pour évaluer une approche (le couloir de naissance fait 40 cm).
- **Contrôleur d'approche + tir** (`microduck-brain/approach.py`, banc `approach_eval.py`) :
  boucle arrêt–regard–rafale (voir ROADMAP Phase 2). Contraintes mesurées (`ZONE_MORTE.md`) :
  rotation du corps morte tête baissée (≥ 1,0) → tête ≤ 0,4 pendant les rafales ; tir
  seulement tête au neutre ; fenêtre de tir ≈ 3–4 cm en profondeur (balle à x ≈ 5,5–8,8 cm),
  ±3 cm en latéral — étroite et dans la zone de balancement des pieds (le pied pousse la
  balle au dernier pas). Remède structurel prévu : kick réentraîné avec DR de position large.
- **Piège du simulateur (2026-10-04)** : MuJoCo coupe le rendu à `znear` × étendue du modèle — 14 cm dans l'appartement :
  tout objet plus proche de la caméra est invisible. Nos scènes du fork fixent `znear=0.0004` ; toute nouvelle grande
  scène doit faire de même. **ToF** : `tofd` (socket `duck-a-tof.sock`, `tof.stream` → `tof.frame` 8×8) +
  `robot.model.tof_beams` + `frames.tof` → obstacles dans le repère du tronc (`microduck-brain/tof.py`, étalonné à 1 cm).
- `robot.do` est exactement le point d'entrée pour nos futurs gestes
  scriptés/entraînés une fois publiés sur le Hub — pas besoin de
  réimplémenter le déclenchement, juste publier avec le bon `--name`.

## État d'avancement (2026-10-05)
- **Session cloud (Claude Code sur claude.ai, pas d'accès au PC/GPU Windows)** : uniquement du comportemental pur
  dans `microduck-brain` (`brain.py`, `exploration.py`, `pont_ha.py`), rien côté `microduck_rl`/RL/GPU. 16 commits, détail complet
  dans `ROADMAP.md` (section "2026-10-05 — session cloud"). En bref : « Occupation autonome et recherche
  d'attention » codée et testée (jeu seul / va vers un habitant ou le chat au-delà de 10 min sans interaction),
  « zone noire » apprise au point de chute, rêves (tête + murmure sonore) pendant la sieste profonde, rituel
  discret au départ (symétrique de l'accueil au retour), fatigue progressive visible (tête, jamais les jambes —
  zone morte de la marche), coin favori appris par activité (chill/nap — pas encore de déplacement vers ce coin,
  pas de navigation-vers-un-point dans `brain.py`), pause avant un passage étroit (`Wander`), s'ébroue après une
  longue immobilité réelle (odom, pas une minuterie), repos forcé sur vraie batterie basse (`battery.percent`
  < 25 %, indépendant de l'énergie comportementale simulée — même limite de navigation : repos, pas déplacement
  vers une station), recul si le chat approche vite (table « Le chat » — distance au chat via `chat.py`, petit pas
  arrière d'1 s au-dessus de la zone morte, jamais une fuite continue ni sur une approche lente), « chat vu au
  salon » publié dans Home Assistant (`binary_sensor.microduck_chat_vu`, via la veille caméra de `chat.py`),
  « heures calmes » nocturnes optionnelles (`Brain(heures_calmes=(23,7))` — réutilise le chemin de l'interrupteur
  HA, opt-in, aucun changement de comportement par défaut). Suite de tests passante (27 dans `test_brain.py` +
  `test_exploration.py` + `test_ha.py`, dont un test d'intégration longue simulation) ; 2 bugs préexistants dans
  `brain.py` trouvés et corrigés au passage (confirmés préexistants via `git stash`, sans lien avec le code ajouté).

## État d'avancement (2026-10-05, soir — session cloud, suite)
- Les 6 « prochaines étapes » de la ROADMAP codées et testées dans `microduck-brain` (95 tests unitaires, rien essayé contre
  `duck-sim` : à faire en premier sur le PC) : bonjour du matin (`[cerveau]` de `ha.toml`), messager (`[[appareil]]` :
  sonnette, machines, prise à puissance ; message redit au retour), main tendue (`main_tendue.py`, ToF), caresse
  (`caresse.py`, écart des servos de tête — hypothèse à valider), 1-2-3 soleil (`mouvement.py` + boutons MQTT),
  navigation vers un point (`navigation.py` : sieste dans le coin favori), garde-fou « chat agacé », réflexes sonores
  (`audio.py` : sursaut, appel, applaudissements, danse au tempo ; micro ALSA non testé).
- **Chantier suivant décidé** (après validation dans `duck-sim`) : **taquiner l'humain** (déplacer/planquer les objets au
  sol, imiter pour se moquer, faux endormi...) — tri en lots A-D et socle commun (budget de malice, signal « stop »,
  mémoire des blagues) dans la ROADMAP, section « Chantier suivant ».
- **Taquineries socle + lot A faits** (`taquineries.py`, 2026-10-05 nuit) ; lots B-D à faire. `duck-sim` ne tourne pas
  dans le cloud tant que `huggingface.co` est bloqué par l'environnement (politiques ONNX).
- **Micro du robot** : occupé par `robotd` (le `pet-detect` officiel est AUDIO ; sentinelle Noise/Voice), rien d'exposé
  aux clients → `audio.py`/`MicroAlsa` à rebrancher (contribution amont : exposer ces événements dans `robot.subscribe`).
- **Fin de nuit (2026-10-05)** : décision de tout coder et de valider d'un coup plus tard. Faits : taquineries lots B, C,
  D (partie sûre), maison (alarme fumée prioritaire, météo, tours HA), social, chargeur appris, état « porté »
  (`safety.picked_up`), caresse par le courant (`currents_ma`). 142 tests dont endurance + invariants de sécurité.
  **Patch amont prêt** : `microduck-brain/contrib/robotd-audio-state.patch` (robotd publie caresse/sons dans `robot.state`).
- **Point d'entrée = `canard.py`** (cerveau + HA + ToF + caméra, `--chat`, `--micro`) : `pont_ha.py` seul lance le cerveau
  sans ToF ni caméra (le canard ne marche alors jamais).
- **Cible de déploiement = SUR le canard** (`microduck-brain/deploy/robot/`, décidé le 2026-10-05) : le cerveau ne parle qu'à
  `robotd`/`tofd`/`mediad` en local (socket ToF officiel : `/run/tofd/tof.sock`). Seules dépendances externes : Home
  Assistant (Pi existant, fonctions maison seulement) ; `deploy/pi/` = repli si CPU/RAM du RK3566 insuffisants.

## Règles d'identité (décidées le 2026-10-06, vérifiées par `microduck-brain/test_regles.py`)
- **Le canard ne s'exprime QU'avec ses sons de canard** (banque officielle : `alarm`, `greet`, `inquire`, `peck`, `chirp`,
  `coo`, `wheee`) : jamais de voix humaine, de synthèse vocale ni de mot.
- **Tout tourne SUR le canard** : aucun appareil réseau n'analyse ses données (images, sons, distances). Seul Home Assistant
  reçoit des états et envoie les événements de la maison. Pas de repli « cerveau sur un Pi ».
- Conséquence : **quacksat écarté** (son envoyé hors du canard + synthèse vocale) → commandes vocales locales
  (`commandes.py`, Vosk hors ligne). Micro mono-client tenu par `robotd` → patches `contrib/robotd-audio-*.patch` +
  `deploy/robot/asound.conf` (dsnoop). `brain.py` découpé en `etats_*.py`.

## Mon niveau
CNC (Haas TM-2P, filetage NPT), impression 3D (Klipper & Prusa MK3S), Blender, Solidworks, développement web. Familier avec ESP32/Python/Rust en hobbyiste (projets Lumi et rover). Travaille actuellement sous Windows, avec Claude Code installé pour ce projet.
