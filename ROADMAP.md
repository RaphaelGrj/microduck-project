# Roadmap Microduck — apprentissage des compétences

> Objectif : faire de Microduck un membre actif et autonome du foyer (présence,
> personnalité, jeu avec moi et avec le chat), pas un gadget de démo.
> Dernière mise à jour : 2026-10-05 (fin de journée).

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
- [x] **Caméra opérationnelle** (2026-10-03) : vidéo en direct dans la console
      officielle (`http://127.0.0.1:8080`, bouton *connect*), 30 FPS, 714 kbit/s,
      0 % de perte, image en portrait (caméra montée d'un quart de tour, comme
      le vrai robot). Ce qui bloquait, et la solution :
      1. `webrtcsink` (`gst-plugins-rs`) n'est packagé nulle part et Pollen ne
         publie que de l'aarch64 → **compilé depuis les sources** ;
      2. la **0.14.5 échoue** (`failed to set sps/pps`) avec le GStreamer 1.28
         d'Ubuntu 26.04 → **la 0.15.4 marche** ;
      3. `webrtcsink` choisit l'encodeur par rang et prenait `nvh264enc` (NVENC,
         rang 257) dont le flux échoue → déclassé via
         `GST_PLUGIN_FEATURE_RANK=nvh264enc:0,nvautogpuh264enc:0`, repli sur `x264enc`
         (Pollen ne fait ce déclassement que pour macOS).
      Scripts reproductibles + pièges : `microduck-brain/scripts-wsl/`.
      **Débloque la Phase 2** (détecteur de balle / chat sur le flux caméra).
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
- [x] « Oui », Curieux, Surpris (tête relevée + petit recul), Fatigué
      (affaissement de tête, puis `sit_toggle` assis, puis relevé) — **tous
      scriptés, sans RL**, et cette fois joués **via `robotd` depuis le
      cerveau** (`microduck-brain/gestures.py`, `robot.head` + `robot.move`
      + `robot.do`). Vérifiés contre `duck-sim` par la mesure des joints de
      tête (amplitudes réelles loguées). `python3 gestures.py <non|oui|
      curieux|surpris|fatigue|fatigue_complet|tous>`.
- [x] Content (trémoussement) — mouvement de tout le corps, probablement
      HORS de portée du scripting command-level → **seul vrai candidat RL
      de la Phase 1**, à traiter plus tard. **Fait sans RL (2026-10-04)** : `robotd` accepte `robot.pose`
      (roulis / tangage du tronc debout, suivis ~1:1 ; la hauteur est ignorée) ; dandinement à 2 Hz ± 0,25 rad
      (± 9°) + contre-balancement de la tête, sans chute (`diag_pose.py`). Joué à la fin d'une impression et au
      retour d'un habitant après une longue absence.

Gestes qui *nécessitent* vraiment du RL (mouvement hors de l'espace de
commande existant), publiables via `uv run publish --kind episodic
--duration-s <s>` une fois entraînés.

Sans entraînement : **le regard** (`head_pose` est déjà une commande de la
marche) → suivre une personne ou le chat des yeux est du logiciel.

Ces gestes + les sons natifs du Microduck = briques du futur système
d'émotions (esprit Lumi, sans écran, pas d'anthropomorphisme visuel).

### Mouvements physiques à entraîner en RL (gestes épisodiques)

Contrairement aux gestes « Non/Oui/Curieux/Content » ci-dessus (résolus
sans RL, tête/tronc seuls), ceux-ci sortent réellement de l'espace de
commande existant — équilibre dynamique du corps entier, pas seulement
tête/tronc — et demandent donc un vrai entraînement (PPO/mjlab, variante
`-Backlash` comme le reste), publiable ensuite via `uv run publish --kind
episodic`.

**Décision (2026-10-05) : un entraînement à la fois, par ordre d'impact
sur l'effet « vivant », pas tous en parallèle.** Reprise dès que le GPU
se libère (après kick tolérant/passe douce), à la prochaine session
code. Ordre proposé, du plus prioritaire au plus accessoire :

1. **Petit bond de joie** (saut vertical, retombée stable) — salutation
   physique énergique, aucun mouvement actuel ne couvre un vrai décollage
   des deux pieds. Le plus gros changement de perception pour l'effort
   le plus contenu.
2. **Secousse complète du corps** (type chien qui s'ébroue, pas que la
   tête) — oscillation du corps entier, contrairement au `Ruffle` actuel
   (tête seule).
3. **Salut/inclinaison plus marqué** (vrai *bow*, déplacement notable du
   centre de masse) — au-delà de l'inclinaison de tronc déjà scriptée via
   `robot.pose`, volontairement petite par sécurité.
4. **Petit frisson/sursaut du corps entier** après une surprise — distinct
   du simple `Startle` de tête, secousse brève de tout le corps à
   rattraper en équilibre.
5. **Pirouette rapide sur place** (rotation yaw dynamique en gardant
   l'équilibre) — plus vif qu'un tourner-sur-soi en marche lente.
6. **Bonds répétés façon excitation** (plusieurs petits sauts d'affilée) —
   équilibre à maintenir sur plusieurs impacts successifs ; naturel une
   fois le bond simple (1) acquis.
7. **Arrêt théâtral avec léger glissement contrôlé** — freinage plus
   abrupt et visible qu'un arrêt de marche normal, effet comique/
   expressif.
8. **Tape du pied, impatient** — appui sur une seule jambe le temps d'un
   tapotement répété de l'autre, équilibre fin sur une jambe.
9. **Étirement sur une jambe** (une patte tenue en l'air, équilibre
   maintenu) — un vrai étirement dynamique, au-delà du `Stretch` actuel
   probablement tête/tronc.
10. **Pirouette sautée** (saut + rotation combinés) — version plus
    spectaculaire de (5), équilibre plus exigeant à l'atterrissage ;
    attend que (1) et (5) soient acquis séparément.
11. **Accroupissement curieux** (s'abaisser fortement pour regarder sous
    un meuble, distinct de `sit_toggle`) — pose basse stable, utile avant
    un `GroundPick` dans un espace bas.
12. **Monter sur un support bas** (coussin, marche, caisse) et y rester
    stable — élargit les « spots favoris » à des surfaces surélevées.
13. **Franchir un petit obstacle en sautant** plutôt que le contourner
    (seuil de porte, jouet au sol) — utile aussi fonctionnellement pour
    la promenade, pas seulement esthétique.
14. **Sprint court** (accélération puis décélération franche, pas la
    marche mesurée habituelle) — pour une poursuite enjouée d'un objet
    qui roule ou d'un jeu avec le chat.
15. **Pas de côté esquive** (petit saut latéral) — pour éviter un objet
    ou « jouer » à se dérober, mouvement latéral franc plutôt qu'un pas
    de rotation.
16. **Dribble au bec en marchant** (pousser/accompagner la balle en
    continu plutôt qu'un tir ponctuel) — complète le kick actuel par une
    interaction de jeu prolongée ; dépend des contrôleurs de la Phase 2.
17. **Petit coup de bec/poussée douce vers une jambe humaine** — pour
    réclamer physiquement de l'attention plutôt que par le son/regard
    seul ; mouvement fin et contrôlé, pas un déplacement du corps entier.
18. **Trébuchement volontaire suivi d'un rattrapage** — presque-tomber
    assumé et rattrapé pour un effet attachant/maladroit ; politique de
    récupération dédiée, différente du `limp_fall` (chute réelle non
    voulue) ; le plus délicat à faire paraître volontaire plutôt que raté.

**À part, hors de cet ordre (exploratoire, pas un geste « gratuit »)** :
- **Pousser une porte entrouverte avec le poitrail/bec** : physiquement
  utile (autonomie réelle dans la maison) mais demande du contrôle de
  force fin, pas seulement de la trajectoire — à isoler comme un
  chantier à part, et à valider d'abord en sécurité (force maximale,
  risque de pincement) avant tout entraînement.

**Matériel externe (UWB, NFC, micro déporté, ESP32, décor physique,
etc.) : simple piste, rien de prévu aujourd'hui** — reste tel quel en
Phase 4 « plus tard », pas dans le chantier actif.

## Phase 2 — Perception et jeu de balle avec vision

- [x] **Détecteur de balle par couleur (classique, sans entraînement)** —
      `microduck-brain/vision.py` (2026-10-03) : images via `GET /frame` de `mediad`
      (PNG 360×640, ~0,13 s), seuillage HSV + filtre de rondeur (non appliqué aux
      objets coupés par le bord de l'image). Testé sur la caméra simulée : balle
      orange et cube cyan repérés, **aucune fausse alerte** sur le sol, le bois et
      les murs. Il reste le **chat** (classe COCO `cat`, petit YOLO pré-entraîné —
      la couleur ne suffira pas) et un test hors simulation (éclairage réel).
- [x] **Suivi du regard** — `microduck-brain/track.py` : le canard tourne la tête
      (`robot.head`) pour centrer la cible ; sens et gains **calibrés
      automatiquement** ; asservissement avec attente de stabilisation (sans elle :
      oscillations divergentes, à cause du retard image 0,15–0,25 s + inertie de la
      tête). **Erreur finale < 2 px en ~4 s** (de 116/226 px au départ), vérifié sur
      image (balle pile au centre). Première boucle perception → action.
- [x] **Contrôleur d'approche bout en bout** (2026-10-03) —
      `microduck-brain/approach.py` + banc d'évaluation `approach_eval.py` (arène
      ouverte, vérité terrain). Boucle « arrêt – regard – rafale » : localise la balle
      dans le repère du tronc (`geometry.py` : pose caméra de `robotd` + intersection
      avec le sol, **0,5–2 cm d'erreur de 11 cm à 1 m**), marche/tourne par rafales,
      s'ajuste dans la fenêtre de tir, ramène la tête au neutre, déclenche
      `kick_left`/`kick_right`. **Résultat (arène vide, balle posée au hasard à 0,5–1 m) :
      10/10 essais réussis à ±30° de relevement, puis 9/10 à ±60° (graines 7 et 8) ;
      14 à 61 s par essai, médiane ~30 s ; les deux pieds servent.** Le seul échec : la
      balle poussée trop fort au dernier pas, qui roule à 3 m (voir « limite structurelle »
      ci-dessous). Avant d'élargir la fenêtre de 1,2 à 1,7 cm : 7/10. Ce que les mesures ont
      imposé (détails : `ZONE_MORTE.md`) :
      * la zone morte de la marche (vx ≥ 0,3, ≤ −0,4, |vyaw| ≥ 1,2) → pas de pilotage
        fin, rafales dont la **durée** dose l'amplitude (table `bursts.py`) ;
      * **tête baissée (≥ 1,0) : la rotation du corps est morte** → tête à ≤ 0,4 pendant
        les rafales, baissée seulement à l'arrêt pour regarder ;
      * **le tir exige la tête au neutre** (0 m/s sinon, 1,2 m/s au neutre) ;
      * **la balle EST visible dans la fenêtre de tir** avec la tête baissée à fond
        (correction de ce qui était écrit plus haut : « invisible au pied ») ;
      * faux positif : les pieds orange du canard au bord bas de l'image, tête baissée
        à fond → rejeté par une zone d'exclusion (aucune balle sous le canard).
- [ ] **Limite structurelle restante : la fenêtre de tir est trop étroite.** Mesurée
      (`kick_sweep.py`) : profondeur ≈ 3–4 cm utiles (balle à x ≈ 5,5–8,8 cm devant le
      tronc, 2 cm plus près que le point d'entraînement 9 cm), latéral ± 3 cm autour de
      ±4,2 cm. Or cette zone est dans la **zone de balancement des pieds** : au dernier
      pas, le pied qui avance **pousse la balle** (la balle repart à 15–20 cm, il faut la
      reprendre) → c'est la cause des échecs restants et du temps perdu. **Remède
      structurel : réentraîner un kick avec une DR de position bien plus large**
      (`BALL_POS_NOISE_XY` ±1,5 cm aujourd'hui dans `microduck_ball_kick_env_cfg.py`,
      et `BALL_OFFSET_X` 9 cm → balle jusqu'à ~20 cm devant, hors de la zone de pas),
      politique toujours aveugle (contrat 61 entrées conservé, donc déclenchable par
      `robot.do`). **Entraînement lancé le 2026-10-04 à 16 h 25** (fork : tâches
      `Mjlab-BallKickTolerant-Flat-Backlash-MicroDuck-Right/Left`, balle de 8 à 15 cm devant et ±2,5 cm latéral,
      3 000 itérations par pied, ~2 h 30 chacune, pied droit puis gauche enchaînés). Évaluation dans duck-sim :
      `~/kick_tol_eval.sh` (export ONNX → `robot.loadPolicy` → balayage x = 7…15 cm → retour à l'officielle).
      **Premier résultat, pied droit à l'itération 1 250 (arène, 36 tirs)** : **28/36** de 7 à 15 cm contre **14/36**
      pour l'officiel, et **13/18 au-delà de 12 cm contre 1/18** (hors de la zone où les pas poussent la balle).
      Défaut : il tape trop fort (jusqu'à 2,9 m/s pour 1,0 visé, entraînement pas encore convergé). `approach.py` :
      profil `tolerant_droit` (`MICRODUCK_TIR`).
- [ ] Le tir part à ±15–25° de l'axe, vers l'extérieur (pied gauche +15…+22°, pied droit
      −10…−27°) : pour VISER une cible, compenser le cap avant de tirer.
- [ ] Cas non couverts par l'évaluation : balle dans le dos (CHERCHER), canard qui
      tombe, pièce encombrée (l'évaluation est en arène vide), distance > 1 m.
- [ ] **Kick doux « passe »** : réentraîner avec un `BALL_TARGET_SPEED`
      bas (1,0 m/s actuellement ; ~0,25 m/s = tape douce) pour passer la
      balle au chat ou à moi.
- [ ] Étudier [laya-vision](https://github.com/r33drichards/laya-vision)
      et quackd pour la structure (⚠ licence CC-BY-NC-SA : OK usage perso).

## Phase 3 — Le cerveau du foyer (cœur du projet, sans RL)

Service hors robot (PC/serveur), parle à `robotd` via le réseau, développé
d'abord contre `duck-sim`. **Calqué sur M9** (mêmes états, même modèle
énergie/humeur) pour pouvoir contribuer en amont ou se brancher dessus.

- [x] Squelette : états M9 + modèle énergie/humeur + transitions (`brain.py`) — **promenade sûre** (2026-10-04) :
      ToF 8×8 → distances libres (`tof.py`, étalonné : mur à 0,84 m mesuré 0,83 m), marche à 0,4 m/s hors zone
      morte, arrêt à 45 cm, rotation du côté dégagé ; 2 × 3 min dans l'appartement : 0 contact, 0 chute
      (plus près : 23 cm d'un tabouret). Pas encore : mémoire d'exploration (« novelty grid » du M9 officiel).
- [x] Les gestes de la phase 1 = vocabulaire des états (Stretch, Ruffle,
      Preen, Sneeze, Startle…) — étirement, ébouriffe, lissage, éternuement scriptés (tête seule, amplitudes
      mesurées), joués en **initiatives rares** (~6/h, jamais le même en moins de 5 min ; étirement au réveil).
- [x] **Mémoire relationnelle** : familiarité par habitant (humains, chat)
      qui rend l'accueil plus chaleureux avec le temps ; habitudes apprises
      (heure de retour, heure de coucher) — `memoire.py` (rencontres, heure habituelle, familiarité qui monte et
      s'oublie, demi-vie 14 j). **Chat** : accueil méfiant → chaleureux (inquire → greet → coo). **Humains (2026-10-04)** :
      présence HA (`person.*`, section `[[habitant]]`) → état `accueil` : réservé au début, chaleureux ensuite,
      **petit signe s'il n'est sorti que 5 min, joie (ébouriffe + « wheee ») après 4 h d'absence** (durée tirée de
      `last_changed` de HA) ; rien en mode calme ; la sieste n'est interrompue que par un retour après une longue absence.
      Testé contre le faux HA. Reste : marcher vers l'entrée (position fiable nécessaire : balises UWB).
- [ ] **Initiative rare et surprenante** (principe Pollen : « un duo
      surprise est un plaisir, un juke-box non »)
- [ ] Home Assistant : partir de `quacksat` (Wyoming), puis exposer
      batterie, humeur, état, pièce comme entités HA — **entités faites** (REST, et **MQTT discovery** le 2026-10-04 :
      appareil « Microduck » créé automatiquement, entités éditables et persistantes, « indisponible » si le cerveau
      s'arrête, interrupteur `switch.microduck_calme` fourni ; testé contre un faux broker `mock_mqtt.py`). Restent :
      la vraie instance (`ha.toml`, `--verifier` teste maintenant aussi les identifiants MQTT), le vocal (quacksat).
- [ ] Premier cas concret : notifications d'impression 3D (Prusa MK3S →
      MK4S via Prusa Connect, Elegoo Saturn 4 Ultra) — le robot vient te
      voir et réagit (son + geste) à la fin ou à l'échec d'une impression

### Chantier actif — tout le comportemental sans RL (2026-10-05)

**Décision (2026-10-05) :** tout ce qui est listé plus bas dans « Pistes
supplémentaires — rendre le robot vivant, compagnon de vie » et qui ne
demande **aucun entraînement RL** (réflexes son/vue, actions vers
l'humain, sommeil/réveil, exploration, ambiance du foyer, nuances
sociales, décor visuel/auto-préservation) **n'est plus une liste « pour
plus tard »** : ça rejoint le chantier actif de `brain.py`/`vision.py`/
`track.py`/`memoire.py`, à brancher au fil de l'eau parce que ça se fait
vite (pas de GPU, pas d'attente d'entraînement). Priorité donnée sur les
nouveaux mouvements RL — voir ci-dessous pour ceux-là. Rien à trier
par avance : tout y passe, dans l'ordre qui tombe bien pendant le
développement du cerveau.

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

### Diagnostic / auto-surveillance (à faire plus tard)

Objectif : que le cerveau sache quand quelque chose chez le robot lui-même
dérive, avant que ça devienne une panne — et que ça remonte dans HA comme
le reste de l'état du foyer.

- **Batterie dans la durée** : historiser charge/décharge par cycle (pas
  juste `battery.percent` instantané) pour repérer la dérive de capacité
  et prévenir avant le remplacement plutôt qu'à l'arrêt sec — utile avec
  les 2 batteries de rechange du pack (rotation à planifier).
- **Santé des servos** : suivre charge/température par articulation dans
  `robot.health` sur la durée ; une dérive localisée (une hanche qui chauffe
  plus que les autres, un backlash qui grandit) signale une pièce à
  surveiller avant la casse.
- **Auto-test au réveil** : petite séquence de vérification (amplitude de
  chaque articulation, trame caméra, trame ToF) jouée au lever, résultat
  publié en entité HA plutôt que découvert au moment où une compétence
  plante en plein jeu.
- **Qualité de connexion par pièce** : carte du signal Wi-Fi/BLE mesuré en
  promenade (déjà en train de cartographier la maison pour l'évitement
  ToF/UWB) → explique les latences ou pertes de trame sans RF à part.
- **Journal des chutes** : fréquence et lieu des déclenchements `limp_fall`
  dans le temps — un tapis ou un seuil de porte qui revient souvent dans le
  journal est un vrai signal d'aménagement, pas juste un incident isolé.

### Capteurs d'état par vision, au-delà balle/chat (à faire plus tard)

Même pipeline que le détecteur de balle (HSV/forme) ou YOLO léger existant,
appliqué à d'autres questions utiles au foyer plutôt qu'au jeu :

- **Porte/fenêtre laissée ouverte** : détection simple de l'état ouvert/fermé
  sur les encadrements déjà dans le champ de ses promenades → entité HA,
  rappel vocal si ouverte à une heure inhabituelle.
- **Lumière oubliée allumée** : repérer une pièce éclairée alors qu'elle est
  vide (croisé avec la présence HA) plutôt que d'ajouter des capteurs de
  luminosité dédiés.
- **Objet au sol / désordre repéré** : un obstacle imprévu sur son trajet de
  promenade (déjà détecté par le ToF pour l'évitement) remonté comme
  événement « objet au sol » exploitable pour `GroundPick` ou juste un
  signalement.
- **État visuel de l'impression en cours** : complément local à
  Prusa Connect / SDCP — un coup d'œil caméra sur le plateau en passant,
  utile si l'API réseau de l'imprimante est indisponible ou pour détecter
  un défaut visuel (spaghetti, décollement) que l'API ne voit pas.
- **Plante qui a besoin d'eau** : repérage visuel simple (feuillage
  affaissé/jauni) sur un passage régulier, en complément ou à la place d'un
  capteur d'humidité dédié.

## Pistes supplémentaires — rendre le robot vivant, compagnon de vie

Suggestions indépendantes des deux ensembles ci-dessus, pensées uniquement
pour la dimension « présence vivante » (pas une nouvelle compétence
technique isolée), dans l'esprit des principes directeurs (couche
comportement > nombre de politiques, pas d'écran, identité sonore).

- **Rythme circadien réel** : une courbe d'énergie/humeur du modèle M9 qui
  suit l'heure du jour (et pas seulement le temps écoulé depuis le dernier
  repos) — plus vif en fin d'après-midi, qui se calme naturellement le
  soir sans qu'on ait besoin d'activer le mode « calme » à la main.
- **Petits rituels de présence** : un geste/son bref et reconnaissable à
  chaque départ/retour d'un habitant détecté par HA (pas la même « fête »
  qu'après une longue absence — un signe discret, cohérent, répété) ; à la
  longue c'est ça qui construit l'impression de présence plus que chaque
  interaction prise seule.
- **Mémoire des objets, pas seulement des habitants** : quand `GroundPick`
  ramasse ou dépose un objet, le robot « se souvient » où il l'a laissé et
  peut revenir le vérifier plus tard (« tiens, mon jouet est toujours là »)
  — réutilise la mémoire relationnelle déjà construite pour les habitants,
  étendue aux objets.
- **Réaction à la musique/au rythme ambiant** : détecter un battement
  régulier au micro (déjà utilisé pour `pet-detect`/bruits) et faire suivre
  un petit mouvement de tête en rythme — pas une danse chorégraphiée,
  juste une réaction qui donne l'impression d'écouter.
- **Personnalité qui dérive lentement avec l'usage** : pondérer légèrement
  les probabilités de transition M9 (plus de `Zoomies`/`Dance` si le jeu
  balle est fréquent chez vous, plus de `Chill`/`Preen` sinon) pour que le
  caractère du robot reflète doucement comment la maison l'utilise, plutôt
  qu'un profil figé au premier démarrage.
- **Vocalisations gratuites, sans fonction** : de temps en temps, un petit
  son de canard sans déclencheur ni message à faire passer (pas un geste
  de l'orchestrateur, juste un bruit de fond occasionnel) — c'est souvent
  ce genre de détail « inutile » qui rend un animal de compagnie vivant
  plutôt qu'un système à états.
- **Conscience du calendrier domestique** : un signe reconnaissable (pas
  une « célébration » scriptée lourde) le jour d'un événement marqué dans
  le calendrier HA du foyer, plutôt qu'une ignorance totale du temps qui
  passe en dehors de la familiarité/habitudes déjà suivies.
- **Spot favori appris, pas imposé** : au lieu de fixer un point de repos
  par défaut, laisser le cerveau remarquer où il finit le plus souvent en
  `Chill`/`Nap` (proximité d'un habitant, lumière, chaleur du radiateur ?)
  et y retourner par préférence — un territoire choisi plutôt que programmé.

### Réflexes autonomes déclenchés par l'environnement (son, vue)

Même principe que « danse si de la musique » : une détection de motif sur
un capteur déjà en place (micro, caméra) déclenche un geste/état existant,
**sans commande ni initiative programmée par horloge** — c'est la
réactivité non sollicitée qui fait la différence avec un système à états.

- **Danse au rythme** : battement régulier détecté au micro → hochements
  de tête en tempo, s'arrête tout seul avec le son (cf. ligne « Réaction à
  la musique » ci-dessus — à fusionner si implémenté).
- **Sursaut au bruit sec et fort** (objet qui tombe, verre cassé, porte
  qui claque, tonnerre) → `Startle`, puis vient regarder d'où ça vient.
- **Réaction aux claquements de main / applaudissements** : motif sonore
  bref et caractéristique → se retourne et s'approche, comme « appelé »,
  sans mot-clé vocal.
- **Rire détecté** (motif de pics sonores courts et répétés, pas besoin de
  comprendre les mots) → vient voir, devient plus enjoué.
- **Silence inhabituel** à une heure où la maison est d'ordinaire bruyante
  (appris via les habitudes déjà suivies) → petit tour d'exploration,
  comme pour aller voir ce qui se passe.
- **Son propre reflet** (miroir, vitre, écran noir) : détecte « un autre
  canard » → curiosité/surprise.
- **Mouvement périphérique sans cible précise** (ombre, rideau, oiseau
  derrière la fenêtre) : bref regard dans cette direction, sans poursuite
  — l'air « distrait » plutôt qu'un radar qui scanne.
- **Quelqu'un qui bouge en rythme devant lui** (danse visible à la
  caméra) : tente de synchroniser un petit mouvement de tête — complément
  visuel à la détection audio du rythme.
- **Bruit de clés dans la porte, avant même l'ouverture** : se tourne déjà
  vers l'entrée — anticipation plutôt que réaction après coup, effet
  « il m'attendait » particulièrement marquant pour l'impression de vie.
- **Bruit de la machine à café / bouilloire le matin** : association
  apprise par répétition avec l'heure du réveil → vient rôder dans la
  cuisine à ce moment-là sans qu'on le lui demande.

### Actions spontanées vers l'humain

Le point commun : agir (ou délibérément s'abstenir) **à l'initiative du
robot envers un habitant précis**, pas en réponse à une commande — c'est
ce registre qui le rapproche d'un animal de compagnie plutôt que d'un
assistant qui attend qu'on lui parle.

- **Tenir compagnie pendant une activité longue et immobile** : un
  habitant assis au même endroit depuis longtemps (présence HA + absence
  de mouvement ToF/caméra, ex. télétravail) → le robot vient se poser à
  côté, sans rien demander — présence plutôt qu'alerte.
- **Discrétion automatique pendant un appel téléphonique** : voix détectée
  sans deuxième interlocuteur dans la pièce → le robot évite de venir
  interrompre, reste en retrait. Une *absence* d'action délibérée est
  aussi un signe de vie/d'attention, pas seulement les initiatives.
- **Réagir à son prénom entendu dans une conversation normale** (pas une
  commande adressée) : tourne simplement la tête vers qui l'a prononcé,
  sans déclencher toute une réponse vocale — juste « j'ai entendu ».
- **Anticiper la caresse** : une main qui s'approche détectée à la caméra
  avant même le contact ToF → légère avance de tête pour « venir à la
  rencontre » du geste plutôt que de le recevoir passivement.
- **Contagion du bâillement** : bâillement audible (motif sonore
  particulier) → petit étirement/bâillement du robot à son tour, comme
  chez un animal.
- **Timidité initiale avec un visiteur inconnu** (pas dans la mémoire
  relationnelle), qui se dissipe au fil de la visite — distinct de la
  méfiance progressive déjà prévue pour le chat, ici appliquée à un humain
  jamais rencontré.
- **Présence silencieuse si le ton de voix est triste/abattu** (variation
  de ton détectée, pas de compréhension du contenu) : s'approche
  doucement et reste là, sans bruit ni geste — soutien discret plutôt
  qu'intrusif, à bien encadrer pour ne jamais paraître surveiller l'état
  émotionnel de quelqu'un.
- **Rejoindre machinalement la pièce à vivre à l'heure des repas** :
  routine apprise par horaire + présence en cuisine/salle à manger,
  plutôt que programmée en dur — vient « traîner par là » comme un animal
  habitué aux horaires du foyer.

### Sommeil et réveil

- **« Rêves » pendant la charge/veille nocturne** : petits mouvements très
  doux et aléatoires (tressautement léger de tête, murmure sonore
  occasionnel), jamais d'amplitude — juste assez pour qu'il ne paraisse
  pas complètement « éteint » quand il recharge.
- **S'ébroue après une longue immobilité réelle**, pas sur minuterie fixe
  — réutilise le geste `Ruffle` déjà existant, déclenché par l'état
  constaté plutôt que par l'horloge.

### Exploration et curiosité

- **Cherche le soleil** : repère une zone de lumière forte au sol (caméra)
  et va s'y installer — « chat qui cherche le rayon de soleil » transposé,
  reconnaissable et gratuit à observer.
- **Remarque un objet qui n'était pas là avant** (comparaison grossière
  avec ce qu'il a l'habitude de voir dans une pièce) → va l'inspecter de
  près, le regarde, éventuellement petit coup de bec curieux.
- **Ramasse un objet au sol et en fait quelque chose, pas juste un
  événement HA** : une fois `GroundPick` déclenché, le robot garde l'objet
  au bec et choisit (selon l'humeur/état M9 du moment) soit de le **cacher
  quelque part** (sous un meuble, dans un coin — comme un chien qui
  enterre un os), soit de le **promener** un moment en se baladant dans la
  maison avant de le lâcher ailleurs qu'où il l'a trouvé. Rejoint la
  « mémoire des objets » déjà notée : savoir où il a laissé une chose
  qu'il a lui-même déplacée devient alors nécessaire, pas juste
  intéressant — sinon même le robot ne « sait » plus où est passé l'objet.
  Garde-fou à prévoir : ne jamais cacher/emporter un objet qui pourrait
  être cherché par un habitant (seuil de taille/catégorie à définir), et
  rapporter l'objet en vue plutôt que le perdre pour de bon.
- **Vient « montrer » une découverte** : s'il repère quelque chose
  d'inhabituel (objet tombé, porte ouverte) alors qu'un habitant est
  présent, il va physiquement le chercher, puis alterne le regard entre
  l'humain et l'endroit — plus vivant qu'une simple notification HA, parce
  que c'est un comportement de signalement actif.

### Ambiance du foyer et évolution dans le temps

- **Se retire si l'ambiance est très bruyante/chaotique** (fête, dispute,
  volume sonore élevé et prolongé) — retrait par préférence plutôt que
  subir n'importe quelle ambiance, renforce l'idée d'un être avec ses
  propres limites.
- **Réagit différemment aux bips des autres appareils** (four, lave-linge
  en fin de cycle, micro-ondes) — curiosité dirigée vers la cuisine/
  buanderie, distincte du cas impression 3D déjà prévu.
- **Rythme différent semaine/week-end**, déduit de l'absence de mouvement
  à l'heure habituelle plutôt que d'un calendrier explicite — plus « zen »
  un dimanche matin où personne ne bouge encore à l'heure attendue.
- **Personnalité un peu saisonnière** (météo HA) : plus cocooning/proche
  d'une source de chaleur en hiver, plus matinal avant la chaleur en été.
- **Motif sonore personnel qui dérive légèrement avec le temps** — pas un
  vocabulaire figé depuis le premier jour, pour donner l'impression qu'il
  « grandit » plutôt qu'il reste identique à sa sortie de carton.

### Interaction avec le reste de la maison

- **Curiosité ou méfiance envers le robot aspirateur** : première
  rencontre prudente (comme avec un visiteur inconnu), qui devient
  habitude — ignore son passage une fois reconnu comme familier, ou
  s'amuse à le suivre un peu. Une vraie relation entre deux « habitants »
  non-humains de la maison.
- **Va se recharger de sa propre initiative avant d'être à court**, pas
  juste une alerte batterie passive — anticipation (« je faiblis, je
  rentre ») plutôt qu'arrêt forcé.
- **Anticipe un orage annoncé** (alerte météo HA) en cherchant un coin
  abrité avant même que le bruit commence — instinct plutôt que simple
  réaction au tonnerre déjà prévue plus haut.

### Préférences et apprentissage non programmé

- **Jouet favori appris** : avec plusieurs balles/objets disponibles,
  développe une préférence pour l'un d'eux selon l'historique de jeu,
  plutôt qu'un comportement identique envers tous — une vraie petite
  manie plutôt qu'un traitement uniforme.
- **Mot ou son déclencheur qui émerge par répétition**, pas pré-câblé :
  si une même phrase/intonation précède souvent une même action, le
  robot finit par y réagir de lui-même — apprentissage associatif
  progressif plutôt qu'un dictionnaire de commandes figé dès le départ.

### Conscience de l'environnement et de lui-même

- **Toilette après une activité poussiéreuse** (CNC, imprimante 3D,
  ponçage détecté au bruit caractéristique de l'atelier) → petit geste
  `Preen`/`Ruffle` après coup, comme s'il « se secouait » après être
  passé dans la poussière.
- **Réagit au fait d'être photographié/filmé** : détecte un téléphone
  pointé vers lui (forme rectangulaire tenue à hauteur, à la caméra) →
  se redresse, pose. **À approfondir (accord donné) : un vrai répertoire
  de poses/expressions/réactions différentes** plutôt qu'un seul geste
  réflexe — à faire varier selon l'état M9 du moment (`Chill` → pose
  calme tête légèrement inclinée, `Zoomies` → pose plus « speed »,
  `Curious` → s'avance vers l'objectif) et à ne pas répéter identique à
  chaque fois (lassitude visuelle sinon, comme pour les gestes de
  phase 1). Prochaine étape concrète : lister 4-5 poses/réactions
  distinctes avant tout script.
- **Baisse spontanément vitesse et volume la nuit** selon la lumière
  ambiante réelle, indépendamment de l'interrupteur « calme » manuel —
  un vrai rythme jour/nuit de fond, pas juste une bascule qu'on actionne.
- **Petit geste d'au revoir en écho à un ton de départ habituel** (la
  phrase/intonation typique avant de sortir), distinct de la simple
  détection de présence qui change — réagit à la manière de le dire, pas
  seulement au fait de partir.

### Sécurité et urgence perçue

- **Alarme incendie / détecteur de fumée** : son très spécifique et
  strident, distinct de tout le reste → réaction d'alerte propre (pas un
  simple `Startle`), va activement chercher un habitant plutôt que rester
  sur place.
- **Sonnette vs coup à la porte** : deux sons différents, deux urgences
  différentes — la sonnette appelle plus vite vers l'entrée qu'un simple
  bruit sourd.
- **Feux d'artifice / pétards**, distincts du tonnerre (répétition rapide,
  motif différent) → réaction de prudence plus marquée et plus longue, se
  met en sécurité plutôt qu'un sursaut isolé.

### Nuances sociales plus fines

- **Distingue le ton en entendant son prénom** : gronder vs câliner — tête
  basse/retrait dans un cas, approche contente dans l'autre, sans
  comprendre le sens des mots, juste le ton.
- **Visiteur récurrent reconnu comme tel** (quelqu'un qui revient chaque
  semaine sans être un habitant — ménage, grand-parent) : familiarité
  intermédiaire entre « inconnu » et « habitant », plutôt qu'une
  reconnaissance tout ou rien.
- **Cherche la présence humaine plutôt que la prise, quand les deux sont
  possibles** : batterie faible mais calme et un habitant proche → va
  d'abord vers lui avant de se recharger, tant que ce n'est pas critique —
  une préférence sociale qui prime sur la pure logique d'autonomie.
- **Salutation sonore individualisée par habitant**, pas un seul son
  générique — une variante reconnaissable par personne, qui s'affine avec
  la familiarité déjà suivie, plutôt qu'un son indifférencié.

### Initiative de jeu, pas seulement réaction

- **Lance lui-même une partie de cache-cache, occasionnellement** : va se
  placer dans une cachette modérée et émet un petit son d'appel — **une
  seule fois, sans insister** si personne ne mord (cohérent avec la règle
  « ne jamais insister » déjà posée).
- **Cherche activement son jouet favori s'il a disparu**, puis abandonne
  progressivement après quelques tentatives sur plusieurs jours — un
  attachement perceptible à un objet précis, pas juste une liste d'objets
  interchangeables.

### Décor visuel et auto-préservation

- **Décorations saisonnières détectées à la vue** (sapin, guirlandes,
  citrouilles) plutôt que par calendrier : comportement plus festif tant
  qu'elles sont visibles — marche même sans intégration calendrier HA.
- **Réaction distincte neige vs pluie par la fenêtre** : la neige (motif
  de mouvement différent, rare) déclenche une curiosité plus marquée que
  la pluie, désormais familière.
- **Re-explore après un réaménagement du mobilier** (une pièce très
  différente de ce qu'il a l'habitude de voir) : revisite la pièce plus
  longuement, comme pour mettre à jour sa carte — réutilise la mémoire
  d'exploration déjà en place.
- **Auto-préservation thermique** : si la télémétrie de température des
  servos (déjà prévue en diagnostic) grimpe, va de lui-même vers une zone
  plus fraîche plutôt que de continuer son activité — relie directement
  le diagnostic à un comportement visible, pas seulement à un journal.

### Nuances sociales et comportementales supplémentaires

- **Toast / geste collectif** : quand les habitants lèvent leur verre
  (geste visuel assez caractéristique), petit relevé de tête synchronisé
  — mimétisme social minimal, sans rien comprendre de l'occasion.
- **Vérifie le chat s'il arrête soudainement de miauler** alors qu'il
  miaule souvent : silence inhabituel *spécifique au chat*, distinct du
  silence général de la maison déjà noté — va voir ce qu'il devient.
- **Jeu de « chaud/froid » improvisé** : un habitant guide par
  l'intonation (ton qui monte en s'approchant d'une cible, baisse en
  s'éloignant, sans mot-clé précis) → le robot ajuste sa direction de
  recherche — jeu basé sur le ton plutôt que sur une commande.
- **Découragement progressif plutôt que tout-ou-rien** : après une
  initiative ignorée (cache-cache proposé, personne ne mord), le délai
  avant une nouvelle initiative du même genre s'allonge tout seul et se
  reconstruit avec le temps — plus fin que « une fois puis silence ».
- **Observe en silence une activité manuelle minutieuse** (soudure, vis,
  peinture de figurine — motif « mains très concentrées, peu de
  mouvement du corps ») : reste à proximité sans interagir, comme un
  animal qui regarde faire sans déranger.
- **Rituel face au miroir qui évolue avec le temps** : la réaction de
  surprise au reflet (déjà notée) laisse place, après plusieurs jours,
  à un bref arrêt pour « se regarder » au réveil plutôt qu'ignorer ou
  sursauter systématiquement — la réaction elle-même change, pas
  seulement sa fréquence.
- **Distingue chahut joueur et vraie dispute** : rires mêlés aux éclats
  de voix vs ton soutenu sans rire → ne se retire que dans le second cas,
  pour ne pas fuir un simple chahut alors que le retrait (déjà prévu) est
  pensé pour une ambiance réellement tendue.

### Pistes physiques (pas seulement comportementales)

Le matériel du Microduck lui-même est fermé (pas de GPIO documenté), donc
ces idées ajoutent des éléments **autour** du robot plutôt que de le
modifier — réseau ou purement passif, cohérent avec les principes déjà
posés (sac à dos ESP32, tags NFC, balises UWB).

- **Jouet sonore** (balle ou objet avec petit haut-parleur/grelot
  intégré) : donne une piste auditive en plus du visuel pour le jeu de
  balle — utile en basse lumière ou si l'objet sort du champ caméra, et
  renforce le lien avec le chat qui réagit aussi au bruit.
- **Tags NFC dans les jouets** (prolonge l'idée déjà notée pour les
  objets au bec) : permet une vraie permanence d'objet — distinguer
  *son* jouet favori d'un objet qui lui ressemble visuellement, plutôt
  que de deviner à la vision seule. Fiabilise directement la « préférence
  apprise » ci-dessus.
- **Tapis de pression ou tag NFC au sol près de l'entrée**, connecté
  réseau : détecte le passage/arrivée plus fiablement que la seule
  présence HA par téléphone — fiabilise l'« anticipation au bruit de
  clés » et l'accueil, indépendamment de qui a son téléphone sur soi.
- **Station de recharge avec repère visuel actif** (anneau lumineux doux
  piloté par une prise/ampoule connectée) : sert de balise de navigation
  pour le retour autonome au chargeur (en plus ou à la place d'UWB pour
  cette seule tâche), et ritualise l'arrivée — la lumière qui s'allume
  doucement rend le retour visible et « accueillant » plutôt que furtif.
- **Petite station météo extérieure connectée** (température/humidité/
  pluie) : alimente directement l'anticipation d'orage et la
  personnalité saisonnière avec une vraie mesure locale, en complément
  de l'API météo HA.
- **Zone de repos dédiée et reconnaissable** (tapis texturé à un endroit
  fixe) : donne un signal physique distinct (texture au sol, perceptible
  par l'IMU/la marche) en plus de la vision pour le « spot favori
  appris » — le robot peut alors le reconnaître même sans bien voir.
- **Accessoire décoratif amovible** (foulard, autocollant saisonnier) que
  les habitants peuvent lui mettre : purement cosmétique, zéro
  électronique, mais renforce le « membre du foyer » de la même façon
  qu'habiller un animal de compagnie — sans toucher au matériel fermé du
  robot.

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

### Phase 2 — état de clôture (2026-10-03, fin de session)
- **Visée** (`approach.py`, `cap_vise`) : le canard se place derrière la balle sur la ligne de tir voulue
  (à l'odométrie), s'oriente, puis approche en ligne droite et tire du pied gauche. Mesuré en arène :
  **11 essais sur 12 dans les ±35° de la direction voulue**, écarts typiques 5–25°, cibles jusqu'à ±120°
  de la ligne canard–balle. Tir étendu vers l'avant (balle jusqu'à 10,5 cm) et jamais déclenché sur une
  position issue de l'odométrie seule.
- **Balle dans le dos / sur les côtés** : retrouvée en arène (relevements +105° et −71° réussis).
- **laya-vision** étudié : VLM SmolVLM-256M qui choisit FORWARD/LEFT/RIGHT/KICK, 86 % de réussite en sim
  (95 % pour son expert scripté), ~0,6 s par décision, poids CC-BY-NC-SA. Notre contrôleur géométrique
  fait mieux sans GPU : pas de VLM nécessaire.
- **Détecteur de chat** : `animaux.py` (YOLOv8n ONNX via `cv2.dnn`, aucune dépendance en plus) — **validé sur 4 photos
  réelles de ton chat (scores 0,86–0,91, boîte correcte, un seul chat à chaque fois) et 0 faux positif sur 5 images
  du simulateur** (2026-10-03). Modèle : `unity/inference-engine-yolo` (HF, `yolov8n.onnx`, 6,4 Mo, GPL-3.0),
  placé dans `microduck-brain/modeles/` (ignoré par git, comme les photos). **Pas encore testé depuis la caméra du
  canard** (pas de chat dans la simulation) : champ de vision, hauteur de caméra et flou de marche à valider sur
  le vrai robot. `geometry.point_au_sol` donne la position au sol d'après le bas de la boîte.
- **Reste à faire** : évaluation dans l'appartement (⚠ il contient ses propres balles orange : `ball_0`…
  à ranger avant chaque essai, sinon le canard vise la mauvaise), distances > 1 m, et les deux items qui
  demandent le GPU (kick à DR large, kick doux) — **reportés, GPU laissé tranquille**.
- **Home Assistant** (prochaine étape) : `quacksat` (andreagenovese/quacksat, Apache-2.0) tourne SUR le
  robot et en fait un satellite vocal Assist (Wyoming) ; il ne publie aucune entité. HA sait déjà lire les
  imprimantes (intégration PrusaLink ; Elegoo Saturn 4 Ultra via HACS `elegoo-homeassistant`, SDCP). Notre
  « cerveau » devra donc (1) lire ces états dans HA (WebSocket ou MQTT) pour réagir, (2) publier l'état du
  robot (batterie, chute, position) en entités MQTT. Attention : quacksat et le cerveau sont deux clients de
  `robotd` (dernier écrit gagne) → prévoir un arbitrage.

### Mise à jour (2026-10-03, suite)
- **Appartement (évaluation non concluante)** : dans la cuisine, 3 tirs réussis sur 8 essais, mais les échecs ne sont
  pas ceux du contrôleur : le banc d'essai a posé la balle **dans un mur** (visible sur l'image), et dans le salon
  la balle orange est **camouflée sur le tapis rouge-saumon** (la partie éclairée se confond avec le tapis).
  Latence de l'image et précision de la vision sont, elles, normales. À refaire avec un placement validé.
  Constat réel utile pour la maison : une balle orange sur un tapis rouge/orangé ne se verra pas à la couleur.
- **Home Assistant — pont écrit et validé contre un FAUX HA et contre `duck-sim`** (`pont_ha.py`, `mock_ha.py`,
  `test_ha.py`, `demo_ha.py`, `HOME_ASSISTANT.md` dans `microduck-brain`) : un changement d'état d'imprimante
  (finished / error / printing…) fait réagir le canard (geste + voix `robot.sound`), l'alerte réveille la sieste ;
  l'état du canard est publié en `sensor.microduck_*`. **Pas encore testé sur ta vraie instance** : il faut l'URL,
  un jeton d'accès longue durée (à coller toi-même dans `~/.config/microduck/ha_token`) et les vrais noms
  d'entités/états des imprimantes (`ha.exemple.toml`).

### Fin de journée 2026-10-03 — état et reprise
- **Chat dans la simulation (validé)** : `make_cat_scene.py` pose une affiche de la photo du chat dans l'arène
  (`bash ~/run-scene.sh arena_chat`) ; `test_chat_affiche.py` : YOLO détecte l'affiche (**score 0,90, 47 ms**) et
  `geometry.point_au_sol` la place à **2 cm** de sa vraie position (estimé 1,18 ; −0,05 m, vrai 1,2 ; 0). Pièges :
  une texture de 1080×1440 fait tomber la capture caméra (503 sur `/frame`) → ≤ 512 px ; une `box` étire la texture
  (stries) → utiliser un `plane` vertical. Photo et scène générée restent locales (ignorées par git).
- **Veille du chat — logique faite et démontrée** (`chat.py`, `test_chat.py`, `demo_chat.py`) : confirmation sur 2 images,
  événement « chat » à chaque nouvelle apparition seulement, délai de grâce 120 s, mémoire du nombre d'apparitions ; dans la
  simulation (affiche) le cerveau passe en `curious` en 0,7 s. **Reste** : suivi du regard sur le chat, mémoire persistante.
- **À faire ensuite, dans l'ordre** : (1) finir la veille du chat (suivi du regard, mémoire persistante) ; (2) évaluation du jeu de balle en appartement
  avec placement de balle validé ; (3) mémoire relationnelle / personnalité (Phase 3) ; (4) MQTT quand Mosquitto sera
  installé ; (5) Home Assistant sur la vraie instance dès que `ha.toml` est rempli (`--verifier`).
- **Entraînement StandUp** : arrêté à 18 h (≈ itération 7 000, point de reprise conservé) ; objectif de reprise : 10 000
  itérations puis évaluation de la politique ; commande dans `~/standup_reprise.txt` (WSL). Le GPU est libre.

### 2026-10-04 — jeu de balle en appartement, chat, promenade
- **Bug du simulateur trouvé** : le plan de coupe proche de la caméra vaut 1 % de l'étendue du modèle → **14 cm dans
  l'appartement** (0,5 cm en arène) : la balle disparaissait dès qu'elle arrivait au pied. Corrigé dans nos scènes
  (`<visual><map znear="0.0004"/>`, fork) ; à signaler en amont.
- **Jeu de balle en appartement, placement vérifié** (`obstacles.py` : jamais dans un meuble ni masquée) :
  8/20 → 13/20 (plan proche) → 15/20 → cuisine **9/10** après la fenêtre fine du pied droit (6,3–8,3 cm) (micro-pas de 0,25 s qui ne poussent jamais la balle — `diag_pousse.py` —
  et fenêtre du pied gauche ramenée à 9,6 cm). Cuisine 6/10, salon 9/10. Restent : balle perdue de vue puis non
  retrouvée (3), tirs bien placés partis de travers (2).
- **Veille du chat complète** : regard qui suit le chat (`robot.look`), mémoire persistante des rencontres.
- **StandUp** relancé le matin, arrêt automatique au point de reprise 10 000 (récompense stable ~47).

### StandUp (se relever) — remis en question (2026-10-04)
- **`robotd` sait déjà se relever** : sa séquence `limp_fall` (code de `robotd`) prédit la chute, rend le canard mou
  pour amortir, ramène les jambes en posture debout puis relance la politique `stand`. En simulation (`diag_chute3.py`) :
  après une vraie chute (canard relâché, tronc à 4 cm), debout en **0,5 à 1 s** couché sur le ventre, le dos ou le côté.
- Notre entraînement StandUp (≈ 7 000 → 10 000 itérations, plusieurs heures de GPU) n'apporte donc quelque chose que
  s'il fait **mieux** sur sol irrégulier, sous les poussées, ou dans des poses que la séquence officielle rate. À
  comparer à 10 000 avant de lui consacrer plus de GPU ; sinon, réserver le GPU au kick tolérant.
- **Évaluation StandUp (2026-10-04, `scripts/eval_standup.py`, 256 canards par départ, avec poussées)** : points 7 000 et
  10 000 **identiques** : 100 % debout depuis le ventre et le dos (relevé en ~0,4-0,5 s), 99,6 % assis, 99-100 % debout.
  Les itérations 7 000 → 10 000 n'ont rien apporté de mesurable. **Recommandation : arrêter d'investir du GPU dans
  StandUp** (la pile officielle se relève déjà ; politique 10 000 conservée). Le GPU va plutôt au kick tolérant.

### 2026-10-04, après-midi
- **Mémoire d'exploration confirmée, gain modeste** (promenades de 6 min, cases de 25 cm visitées) : avec 12, 12, 15, 12
  (moyenne 12,75) ; sans 5, 14, 8, 13, 11 (moyenne 10,2). Forte variance ; gardée active. 0 chute, 0 contact.
- **Sécurité — les marches** : `robotd` n'a pas de protection contre les chutes (étude `quacknav`). `tof.py` détecte
  maintenant les vides (rayon > 4 cm sous le sol, ≥ 2 rayons), avec la pose de tête datée à l'instant de la trame ToF et
  la verticale tirée de la gravité : 0 faux vide sur 4 500 trames en promenade. Scène `arena_marche` (estrade de 15 cm) :
  tête au neutre le bord n'est vu que trop tard (0/3) ; **tête baissée de 0,3 rad, 3/3, arrêt 41 à 52 cm avant le bord**
  → la promenade marche tête un peu baissée.
- **quacksat / quacknav étudiés** (`microduck-brain/QUACKSAT_QUACKNAV.md`) : pendant une conversation vocale (entité
  `assist_satellite` de HA), le cerveau se tait ; pièce et « aller à l'entrée » à confier plus tard à `quack-navd`.
- **Home Assistant** : accueil des habitants (présence), publication MQTT discovery, satellite vocal — tout testé
  contre de faux HA / broker. **Vraie instance connectée le soir** (HA 2026.8.3 : REST, WebSocket et écoute en direct
  OK ; `person.raphael` et la Saturn 4 Ultra branchées ; pas de PrusaLink ni d'`input_boolean` calme dans HA).

### 2026-10-04, soir — tir tolérant final, jeu avec le chat
- **Tir tolérant droit final (it. 2 999)** : 26/36 au balayage (it. 1 250 : 28/36 ; officiel : 14/36), un peu plus doux
  de loin (0,5–1,2 m/s à 13–15 cm). **Jeu complet en appartement** (gauche officiel) : cuisine 7/10, salon 8/10 contre
  9/10 et 9/10 avec l'officiel — pas de gain mesuré (le pied droit n'a tiré que 4 fois sur 20) ; profil par défaut
  inchangé (`officiel`), à rejuger avec le pied gauche tolérant. En arène : 17/20 contre 19/20.
- **Jeu avec un joueur** (`microduck-brain/jeu.py`, banc `jeu_eval.py`, affiche du chat) : chercher le joueur (YOLO),
  le placer à l'odométrie, viser de la balle vers lui (`Approche(cible_vise=...)`), garde-fous (joueur parti 20 s = fin,
  pas de passe vers un chat à moins de 80 cm de la balle). **3 passes réussies sur 8, 3 sur 4 quand le chat est trouvé**
  (écarts +11, −9, −15, −26°). Pièges : l'affiche vue de biais est classée « chien » (accepté) ; d'un côté elle ne dépasse
  pas 0,28 (artefact de l'affiche plate, à revoir avec un vrai chat).
- **Passe douce** : tâches `BallKickPasse` (fork, 0,5 m/s visé, dépassement pénalisé −10) ; entraînement du pied droit
  en file après le tolérant gauche (accord de l'utilisateur).
