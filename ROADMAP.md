# Roadmap Microduck — apprentissage des compétences

> Objectif : faire de Microduck un membre actif et autonome du foyer (présence,
> personnalité, jeu avec moi et avec le chat), pas un gadget de démo.
> Dernière mise à jour : 2026-10-01.

## Principes directeurs

1. **Ne pas réentraîner ce que Pollen livre déjà.** Le dépôt officiel
   [`pollen-robotics/microduck-policies`](https://huggingface.co/pollen-robotics/microduck-policies)
   fournit : `alpha_walking`, `alpha_stand`, `velstand`, `alpha_sitstand`,
   `alpha_ground_pick`, `ball_kick_left`, `ball_kick_right`, `roulade`,
   `roller`, `roller_crouch`. Réentraîner une marche sert à *apprendre le
   pipeline*, pas à gagner une capacité.
2. **La vision et l'intelligence vivent au-dessus des politiques RL.**
   Contrat d'observation commun à toutes les politiques : 61 dims =
   48 proprioception + `twist(3)` + `head_pose(4)` + `body_pose(6)`.
   **Aucune politique ne voit la caméra.** La perception pilote donc les
   commandes (vitesse, regard) et déclenche des politiques épisodiques.
   C'est l'architecture de `laya-vision-microduck-kick` (le modèle voit la
   caméra et choisit FORWARD / LEFT / RIGHT / KICK au-dessus de la marche
   officielle).
3. **Toujours entraîner les variantes `-Backlash`** (±1° de jeu par servo)
   pour préparer le sim2real.
4. **Ce qui rend le robot vivant, c'est surtout la couche comportement**
   (orchestrateur + vocabulaire de gestes + sons), pas le nombre de
   politiques.
5. **S'aligner sur le futur cerveau officiel (jalon M9 de Pollen)** plutôt
   que d'inventer une architecture concurrente. M9 = machine à 16 états
   (Chill, LookAround, Wander, TurnInPlace, Zoomies, Startle, Stretch,
   Ruffle, Preen, Sneeze, Dance, GroundPick, Nap, BallPlay, Petted, Held)
   sur un modèle énergie/humeur. Non porté dans le daemon actuel, placé
   « plus tard, délibérément » dans leur roadmap → contribution possible.
   Réf. : `pollen-robotics/microduck` → `docs/ideas/autonomous_behavior.md`
   et `docs/project/roadmap.md`.

## Ce que le robot perçoit (vérifié dans le runtime officiel)

| Sens | Matériel / composant | Usage foyer |
|---|---|---|
| Vue | Caméra IMX219 (~62° HFOV) + NPU 0,8 TOPS (RK3566), `duck-detect` (YOLO, en cours) | Chat, ballon, personne en local |
| Profondeur | ToF 8×8 dans la tête (VL53L8CX, `tofd`) | Obstacles, distance de la main |
| Toucher | Micro sur la tête + `pet-detect` | Caresse détectée → roucoule |
| Ouïe | Même micro | Bruit / voix, réactions sonores |
| Équilibre | IMU + odométrie par contact des pieds | Position, chute, soulevé |
| Social | BLE + RSSI | Distance approximative (téléphones, autres canards) |
| Voix | Synthé embarqué (`sounds`) | Langage canard expressif |

## Phase 0 — Maîtriser le pipeline (en cours)

- [x] Environnement WSL2 + CUDA + `microduck_rl` (fork) opérationnel
- [x] Premier entraînement `Mjlab-Velocity-Flat-MicroDuck` (pause it. 2000)
- [x] **Entraînement Velocity-Flat arrêté délibérément** (2026-10-01) : objectif
      pipeline atteint, inutile de consommer du GPU sur une marche déjà
      fournie par `alpha_walking`/`velstand`. Checkpoint gardé si besoin de
      comparer un jour.
- [x] **Export ONNX** du checkpoint it. 2000 → `policies/own/velocity_flat_it2000.onnx`
      (fork `microduck_rl`, pas commité — fichier binaire local)
- [ ] Comparer en sim notre marche (it. 2000) à `alpha_walking.onnx`
- [x] **`publish --dry-run` validé** : 61→14 ok, smoke run fini/non-constant,
      bundle (policy.onnx + manifest.json + README.md) généré dans
      `publish-velocity-test/`. Chaîne de publication opérationnelle.
- [x] **Simulateur officiel trouvé** : `pollen-robotics/microduck-simulator`
      (HF Space, 100% navigateur, WASM) — à utiliser pour tester les
      compétences OFFICIELLES (marche, sitstand, roulade, kicks, rollers),
      accessible même depuis un téléphone. Pour nos propres checkpoints :
      `uv run play --viewer viser` (lecture) ou `scripts/infer_policy.py`
      (interactif, WSLg) — pas d'équivalent officiel pour du custom.
- [x] **`VelStand-Rough-Backlash` abandonné** : utilise de la distillation
      (`PpoWithExpertBc`) depuis un checkpoint **privé** Pollen sur wandb
      (`pollen-robotics/mjlab_microduck/69u48n8l`) — 403 Forbidden même avec
      un compte perso. Ce n'est pas spécifique à Rough-Backlash : **toutes**
      les variantes VelStand (Flat/Rough × Backlash) en dépendent.
- [x] **`StandUp-Rough-Backlash` lancé à la place** : du PPO pur (pas de
      distillation), c'est le cœur du "se relever après être tombé" que
      VelStand aurait ajouté à la marche. 4096 env, `logs/rsl_rl/microduck_stand/`.
      **Mis en pause à l'itération 2000** (2026-10-01 21:38, checkpoint
      `model_2000.pt` sain — arrêt propre via SIGTERM après que SIGINT n'a
      pas suffi cette fois). Métriques à cet arrêt : hauteur et verticalité
      déjà quasi au maximum (`height_stand` ~0.97, `upright_sharp` ~0.98),
      poussées actives (`push_magnitude` 0.3 m/s et ça grimpe), aucun crash.
      **Reprise rapide** :
      ```
      cd ~/microduck_rl
      uv run train Mjlab-StandUp-Rough-Backlash-MicroDuck --env.scene.num-envs 4096 \
          --agent.logger tensorboard --agent.resume True \
          --agent.load-run 2026-10-01_18-53-15_microduck_stand
      ```
      Durcir les paramètres de poussée reste à faire une fois qu'on a un
      résultat plus complet.

**Pourquoi c'est prioritaire :** un robot qui tombe et ne se relève pas
n'est pas autonome — et le chat va le bousculer.

## Phase 0 bis — Prendre en main `duck-sim` (le robot avant le robot)

`pollen-robotics/microduck` → `scripts/duck-sim` fait tourner **les vrais
daemons** (`robotd`, `tofd`, `mediad`…) contre un Microduck MuJoCo
(`duck-body`, fourni par `microduck_rl`). Tout ce qui se code contre le
robot se code ici dès maintenant.

- [x] Installer Rust dans WSL, cloner `microduck` à côté de `microduck_rl`
- [x] **`scripts/duck-sim` opérationnel** (2026-10-01) : vrais daemons
      (`robotd`/`tofd`/`configd`/`updaterd`) contre le canard MuJoCo, 50/50 Hz,
      healthy. Validé en conditions réelles : `robot.do roulade` (déclenche
      une politique, queued → exécutée → redebout) et `drive` (`robot.move`,
      marche 8s puis arrêt automatique par le deadman).
- [x] Scène `apartment` (6 pièces, 7×6 m) : `DUCK_SIM_SCENE=apartment` — en service.
- [ ] **Caméra (`DUCK_SIM_CAMERAS=a`) bloquée** : `webrtcsink` vient de
      `gst-plugins-rs`, packagé dans aucune distro Debian/Ubuntu. Le script
      officiel (`setup-gstreamer.sh`) télécharge des binaires précompilés,
      mais **uniquement pour aarch64** (le vrai robot) — rien pour notre
      WSL x86_64. Contournement possible : compiler `gst-plugin-webrtc`
      depuis les sources (`gst-plugins-rs` @ 0.14.5, `cargo cinstall`) —
      pas fait, pas bloquant pour l'instant (rien côté Phase 0bis n'a besoin
      de la caméra). À faire quand on attaque vraiment la Phase 2 (vision).
- [x] **Inventaire IPC `robotd` fait et vérifié contre `duck-sim` réel**
      (2026-10-01). Un écart doc/réel trouvé et corrigé : `robot.do` attend
      le champ **`skill`**, pas `name` comme la doc le suggérait.
- [x] **Premier script Python externe** : `poc_robotd_client.py`, nouveau
      repo [`RaphaelGrj/microduck-brain`](https://github.com/RaphaelGrj/microduck-brain)
      (Phase 3 — le futur cerveau vit hors du repo d'entraînement). Parle en
      direct au socket JSON-RPC/NDJSON (pas via `robotctl`) : `subscribe`,
      lecture de trames `robot.state`, `robot.move`, `robot.stop`, `robot.do`
      — tout validé contre `duck-sim`.
- [ ] Premier script Python externe qui pilote le canard simulé via la
      socket `robotd`

## Phase 1 — Vocabulaire expressif (meilleur ratio vivant/effort)

**Révision (2026-10-01) :** `Mjlab-PoliteBow-Flat-MicroDuck` n'existe pas —
c'est un nom d'exemple dans la doc de `publish`, pas une tâche réelle.
Plus important : le premier geste (« Non ») s'est avéré **ne demander
aucun entraînement RL**. `head_offset` est déjà une commande acceptée par
la politique debout (`alpha_stand`) — un script qui fait osciller
`head_offset[2]` (yaw) dans le temps suffit. Implémenté directement dans
`microduck_rl` (fork) → `scripts/infer_policy.py` : touche **N**, 3
oscillations sur 1,8s, testé et fonctionnel (voir `trigger_gesture` /
`update_gesture` dans `PolicyInference`). **Donc avant d'entraîner quoi
que ce soit pour les gestes suivants, essayer le scripting d'abord** —
RL seulement si le scripting est insuffisant :

- [x] « Non » (secouer la tête) — scripté, pas d'entraînement, touche N
- [ ] « Oui » (hochement) — probablement scriptable pareil (head_offset[1],
      pitch)
- [ ] Curieux (penché + tête inclinée) — probablement scriptable (head_offset
      pitch+roll statique)
- [ ] Surpris (sursaut, petit recul) — peut-être scriptable via body_pose /
      vel_cmd ponctuel, à essayer avant RL
- [ ] Content (trémoussement) — mouvement de tout le corps, probablement
      HORS de portée du scripting command-level → candidat RL réel
- [ ] Fatigué (bâillement / étirement avant de s'asseoir) — combinaison
      head_offset (affaissement) + déclenchement sitstand, à tenter scripté
      d'abord

Gestes qui *nécessitent* vraiment du RL (mouvement hors de l'espace de
commande existant), publiables via `uv run publish --kind episodic
--duration-s <s>` une fois entraînés.

Sans entraînement : **le regard** (`head_pose` est déjà une commande de la
marche) → suivre une personne ou le chat des yeux est du logiciel.

Ces gestes + les sons natifs du Microduck = briques du futur système
d'émotions (esprit Lumi, sans écran, pas d'anthropomorphisme visuel).

## Phase 2 — Perception et jeu de balle avec vision

- [ ] Détecteur sur le flux caméra : ballon **et chat** (classe `cat` de
      COCO, pré-entraînée — aucun entraînement nécessaire). Commencer
      classique (couleur / petit YOLO) avant un modèle vision-langage.
- [ ] Contrôleur d'approche : détection → `twist` (approche) + `head_pose`
      (suivi) → déclenche `ball_kick_left` ou `ball_kick_right` selon le
      côté du ballon.
- [ ] Kick plus tolérant au placement : élargir la DR de position du
      ballon (±2 cm aujourd'hui dans `microduck_ball_kick_env_cfg.py`).
- [ ] **Kick doux « passe »** : réentraîner avec un `BALL_TARGET_SPEED`
      bas (1,0 m/s actuellement ; ~0,25 m/s = tape douce) pour passer la
      balle au chat ou à moi.
- [ ] Étudier [laya-vision](https://github.com/r33drichards/laya-vision)
      et quackd pour la structure (⚠ licence CC-BY-NC-SA : OK usage perso).

## Phase 3 — Le cerveau du foyer (cœur du projet, sans RL)

Service hors robot (PC/serveur), parle à `robotd` via le réseau, développé
d'abord contre `duck-sim`. **Calqué sur M9** (mêmes états, même modèle
énergie/humeur) pour pouvoir contribuer en amont ou se brancher dessus.

- [ ] Squelette : états M9 + modèle énergie/humeur + transitions
- [ ] Les gestes de la phase 1 = vocabulaire des états (Stretch, Ruffle,
      Preen, Sneeze, Startle…)
- [ ] **Mémoire relationnelle** : familiarité par habitant (humains, chat)
      qui rend l'accueil plus chaleureux avec le temps ; habitudes apprises
      (heure de retour, heure de coucher)
- [ ] **Initiative rare et surprenante** (principe Pollen : « un duo
      surprise est un plaisir, un juke-box non »)
- [ ] Home Assistant : partir de `quacksat` (Wyoming), puis exposer
      batterie, humeur, état, pièce comme entités HA
- [ ] Premier cas concret : notifications d'impression 3D (Prusa MK3S →
      MK4S via Prusa Connect, Elegoo Saturn 4 Ultra) — le robot vient te
      voir et réagit (son + geste) à la fin ou à l'échec d'une impression

## Interactions par habitant

### Humains

| Interaction | Entrées | Sorties |
|---|---|---|
| Accueil au retour (plus joyeux après une longue absence) | Présence HA (téléphone) | Marche vers l'entrée, son + geste |
| Caresse | `pet-detect` | Roucoulement (natif), état Petted, geste content |
| Main tendue | ToF (suivi de main) | Regard, approche, « picore » |
| Commandes vocales | quacksat / Wyoming | Réponse en sons de canard (oui / non / hésitation), pas de voix humaine |
| Messager physique (impression, lave-linge, sonnette) | HA | Vient te voir là où tu es |
| Routines (étirement du matin, sieste du soir, heures calmes) | Heure, HA | États Stretch / Nap |
| Jeux : balle, 1-2-3 soleil, cache-cache au son | Caméra, micro | Phase 2 + états |

Identification des humains : **présence HA plutôt que reconnaissance
faciale** (plus fiable, plus respectueux).

### Le robot dans la maison (HA)

- **Capteur** : chat vu au salon, objet au sol, bruit inhabituel
- **Interface** : geste ou caresse qui déclenche une scène
- **État** : batterie, humeur, pièce, activité en entités HA

### Règles de vie (non négociables)

- **Vie privée** : image et son traités en local, aucun flux caméra
  sortant par défaut ; tout ce qui est social est opt-in.
- **Interrupteur « calme »** dans HA : veille, silence, sieste forcée.
- **Ne jamais insister** : une interaction ignorée diminue l'envie, elle
  n'augmente pas la sollicitation (humains comme chat).

## Le chat 🐈

### Interactions prévues

| Interaction | Mise en œuvre | RL ? |
|---|---|---|
| Le suivre du regard | `head_pose` piloté par la détection | Non |
| Réagir à son arrivée (son + geste) | Gestes de la phase 1 | Déjà fait en phase 1 |
| Reculer s'il approche vite | Marche arrière (`lin_vel_x` ∈ [-0,4 ; 0,4] m/s) | Non |
| Le suivre à distance | Suivi de cible via `twist` | Non |
| **Lui passer la balle** | Kick doux (phase 2) | Oui (config) |
| Cache-cache / 1-2-3 soleil | États de l'orchestrateur | Non |
| « Chat vu au salon » dans HA | Entité / événement HA | Non |

Jeu phare : **ballon partagé** — le robot repère la balle et le chat, puis
pousse doucement la balle vers lui.

### Garde-fous (non négociables)

- Le chat peut **toujours partir** : jamais de poursuite s'il s'éloigne,
  jamais le coincer, abandon après quelques secondes.
- **Sons modérés** à proximité ; première rencontre progressive (robot
  immobile, regard seulement).
- **Pas de geste rapide** sous un seuil de distance (risque de pincer une
  patte ou la queue dans les articulations).
- **Mode « chat agacé »** : renversé plusieurs fois de suite → s'assoit
  et passe en veille plutôt que de recommencer.

## Phase 4 — Plus tard

- `GroundPick` : objets / tags NFC au bec
- Localisation UWB (DWM1001-DEV, ancre origine 0,0,0) → navigation vers
  des points nommés
- Sac à dos ESP32 (BLE), orchestré par le serveur
- Rollers, roulade : spectacle
- À surveiller : branche amont `soft_carpet` (état inconnu, pertinente
  pour les tapis)

## Tableau de synthèse

| Compétence | Officielle ? | Apport vivant / autonome | Effort |
|---|---|---|---|
| Marche + relevé (VelStand Backlash renforcé) | Oui | Socle de l'autonomie | Moyen |
| Gestes expressifs | Non | ★★★ personnalité | Faible |
| Regard / suivi de tête | Commande existante | ★★★ présence | Logiciel |
| Cerveau du foyer (aligné M9) | Non (M9 non porté) | ★★★ autonomie | Élevé |
| Détection ballon + chat | — | ★★★ perception | Moyen |
| Balle avec vision + passe douce | Kick oui, vision non | ★★★ jeu (moi + chat) | Élevé |
| Assis / repos | Oui | ★★ rythme de vie | Nul |
| Ramassage au sol | Oui | ★★ objets | Faible–moyen |
| Roulade, rollers | Oui | ★ spectacle | Nul |

## Prochaines actions

1. Relancer l'entraînement Velocity-Flat en arrière-plan (GPU).
2. Installer et lancer `duck-sim` (scène apartment + caméra).
3. Inventaire de l'API `robotd` utile au cerveau.
4. Puis : `VelStand-Rough-Backlash` renforcé, premier geste (« non »).
