# Roadmap Microduck — apprentissage des compétences

> Objectif : faire de Microduck un membre actif et autonome du foyer (présence,
> personnalité, jeu avec moi et avec le chat), pas un gadget de démo.
> Dernière mise à jour : 2026-10-07, nuit (appli sur Android, ordinateur et iPhone ; démo en ligne).

## Où on en est (2026-10-07) — à lire en premier

**Fait, sans robot.**
- **Cerveau** (`microduck-brain`) : machine à états M9 complète, personnalité, jeu de balle avec vision (`approach.py`),
  le chat, taquineries, vie de la maison, diagnostic, Home Assistant facultatif. 357 tests.
- **Application** (APK 1.1, servie par le canard, anglais compris) : tout le pilotage, les réglages, la santé, le
  design 3D, la marketplace (`microduck-catalogue`), les invités, etc.
- **RL** (fork `microduck_rl`) : marche, StandUp (abandonné, robotd se relève seul), tir tolérant droit fini.
- Les trois dépôts sont fusionnés dans `main` (`develop` pour `microduck_rl`).

**Pas encore validé : presque tout le comportemental depuis le 2026-10-05.** Ce code n'a tourné que dans les tests, pas
dans `duck-sim` (le cloud n'y a pas accès). C'est la prochaine étape, elle ne demande ni GPU ni robot.

**Ce qu'on peut encore faire SANS GPU (hors RL)**, par ordre d'utilité :
1. **Validation groupée dans `duck-sim`** sur le PC : `scripts-wsl/valider-tout.sh` (~45 min, CPU), puis corriger ce
   qui casse. C'est le plus important : des semaines de code jamais exécuté contre de vrais daemons.
2. **Essais sur le vrai matériel de la maison**, sans le canard :
   - imprimantes : PrusaLink de la MK4S (lecture, envoi d'un G-code), SDCP de la Saturn 4 Ultra ;
   - Home Assistant réel : pont, MQTT discovery avec Mosquitto, actions `[[action]]` ;
   - l'APK sur le téléphone : démo, présence par le Wi-Fi, widget, notifications.
3. **Clé de signature et publication** : `android/creer_cle.sh`, puis la première release GitHub.
4. **Préparer la livraison** :
   - étude du NPU du RK3566 (conversion RKNN du détecteur du chat) ;
   - `bench_cerveau.py` prêt ;
   - contributions amont à Pollen (patches `contrib/robotd-audio-*`, machine M9).
5. **Contenu** : vraies pièces dans le catalogue (coques, G-code), chorégraphies partagées.
6. ~~Versions de l'appli pour ordinateur et iPhone~~ **faites** (2026-10-07) :
   - ordinateur : `ordinateur/` (Electron), construite par GitHub pour Windows, macOS et Linux ;
   - iPhone : l'appli web installée depuis Safari.

   Le design gagne le code couleur, « Mes couleurs » et le partage des schémas (fichier, QR, `schemas/` du catalogue).
   L'APK (1.3) est maintenant publié par GitHub avec la clé de l'utilisateur.
   Démo en ligne : <https://raphaelgrj.github.io/microduck-brain/?demo>, publiée par `pages.yml`. Il reste à régler
   Settings → Pages → Source = « GitHub Actions » (le premier essai a échoué sans ce réglage).
7. **Lot 9, fait (APK 1.4)** :
   - minuteurs et rappels à heure fixe (`planning.py`) ; réveil doux (routine « reveil », état `Signal` qui monte
     doucement et s'arrête d'une caresse) ;
   - graphique d'humeur sur 7 jours et bilan du mois (image) ;
   - raccourcis de l'icône Android et sauvegarde automatique chaque semaine ;
   - carte Home Assistant (`homeassistant/microduck-card.js`).

   **Prochaine discussion : le canard lui-même** (évolutions du robot, pas de l'appli).

Au-delà, le travail sans robot s'épuise : les réglages fins (seuils, gestes, caresse, index du bec) demandent le vrai
canard.

**Ce qui demande le GPU (RL)** :
- tir réentraîné avec une randomisation de position large (fenêtre de tir actuelle : 3–4 cm) ;
- tir gauche et passe douce (`~/kick_reprise.txt`) ;
- à terme, une politique de balle qui voit vraiment (objectif n°1 du projet), et des gestes épisodiques entraînés
  (Phase 1).

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
6. **Ordre de développement imposé par la dépendance matérielle (décision
   2026-10-05) : toute fonction qui dépend d'un appareil externe —
   **à l'exception de Home Assistant/réseau**, déjà en place — n'est
   développée qu'une fois **toutes** les fonctions autonomes (robot seul)
   terminées.** Concrètement, dans le tableau de dépendance ci-dessous :
   toute la colonne « Robot seul » passe avant toute la colonne
   « Matériel à ajouter » (et avant la partie « appareil externe » des
   lignes « Mixte »), quel que soit l'ordre dans lequel les idées ont été
   notées. La sous-section « Pistes physiques » (jouet sonore, NFC,
   station météo, etc.) reste donc en Phase 4, non entamée, jusqu'à ce que
   le chantier autonome soit vidé.

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

**Ajouts du 2026-10-07 (gestes du corps demandés par les comportements « vivants »)** — même file d'attente GPU,
un à la fois :
- **Trépigner** (piétinement rapide sur place, joie/impatience) : variante de (6)/(8) ; joué par l'état `excite`
  (balle soulevée) et l'attente à la porte, qui se contentent pour l'instant de la tête, du dandinement `robot.pose` et
  de sons.
- **Saut de joie** = (1) ; **s'ébrouer du corps** = (2) (aujourd'hui : tête seule après une longue immobilité).
- **Se gratter avec la patte** (une jambe levée vers la tête, équilibre sur l'autre) : geste rare au repos ; dépend
  de l'équilibre sur une jambe acquis en (8)/(9).
- **S'allonger sur le flanc** pour la sieste (épisodique, pose basse stable + relevé) : la bouderie et la sieste
  profonde l'utiliseraient ; vérifier d'abord en sim que la pose est un équilibre stable (règle AGENTS.md).
Chaque geste publié se branche dans le cerveau par `robot.do {"skill": …}` sans autre changement d'architecture.

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

Développé d'abord contre `duck-sim` comme un service externe pour itérer
vite, mais **contrainte matérielle actée (2026-10-05) : le robot ne doit
dépendre d'aucun appareil externe énergivore pour fonctionner au quotidien.**
Pas de PC/serveur allumé en permanence comme « cerveau » — le budget de calcul
externe permanent est plafonné, pour l'instant, à un **Raspberry Pi 3B+** (déjà
mesuré : pont + cerveau comportemental à 29 Mo / < 1 % CPU) et/ou des **ESP32**
(capteurs, triggers, pas de calcul lourd). **Calqué sur M9** (mêmes états,
même modèle énergie/humeur) pour pouvoir contribuer en amont ou se brancher
dessus.

**Conséquence sur la perception lourde (vision/audio à base de deep
learning)** : le Pi 3B+ n'a pas de NPU et ne peut pas faire tourner du
YOLO (déjà noté plus bas). La seule ressource de calcul IA embarquée
disponible sans dépendance externe est donc le **NPU du robot lui-même**
(RK3566, 0,8 TOPS) — à profiler réellement à la livraison. D'ici là,
toutes les idées de reconnaissance ajoutées dans « Pistes supplémentaires »
(chat, objets, miroir, oiseaux, applaudissements, etc.) restent des
**candidats à trier une fois le budget NPU mesuré**, pas des acquis :
priorité à tout ce qui peut se faire sans deep learning (couleur HSV,
détection de mouvement par différence d'images, seuils audio simples type
clap/débit d'eau), le reste passera un par un sur le NPU embarqué, pas en
continu ni en parallèle tant que la marge réelle n'est pas connue.

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
| Caresse | `pet-detect` ; **en attendant : écart des servos de tête** (`caresse.py`, 2026-10-05) | Roucoulement (natif), état Petted, geste content — **fait** (amplitude réelle à valider sur le robot) |
| Main tendue | ToF (suivi de main) — **fait** (`main_tendue.py`, 2026-10-05) | Regard, « picore » (sans approche : zone morte de la marche) |
| Commandes vocales | ~~quacksat / Wyoming~~ → **reconnaissance locale** (`commandes.py`, Vosk hors ligne, 2026-10-05) | Réponse en sons de canard (oui / non / hésitation), pas de voix humaine — **fait**, micro partagé à valider |
| Messager physique (impression, lave-linge, sonnette) | HA — **fait côté maison** (`[[appareil]]`, prise à mesure de puissance, 2026-10-05) | Réagit, et **redit le message au retour** de l'habitant absent ; « vient te voir » attend une position de l'habitant (UWB) |
| Routines (étirement du matin, sieste du soir, heures calmes) | Heure, HA | États Stretch / Nap — **faits** (heures calmes, bonjour du matin, `[cerveau]` de `ha.toml`) |
| Jeux : balle, 1-2-3 soleil, cache-cache au son | Caméra, micro | Phase 2 + états — **1-2-3 soleil fait** (`mouvement.py` + état `soleil`, bouton HA) ; cache-cache au son : pas de direction du son (micro mono ?) |

Identification des humains : **présence HA plutôt que reconnaissance
faciale** (plus fiable, plus respectueux).

### Le robot dans la maison (HA)

- **Capteur** : chat vu au salon **(fait, 2026-10-05 — `binary_sensor.microduck_chat_vu`)**, objet au sol, bruit inhabituel
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
| Reculer s'il approche vite | Marche arrière (`lin_vel_x` ∈ [-0,4 ; 0,4] m/s) | Non — **fait (2026-10-05)** |
| Le suivre à distance | Suivi de cible via `twist` | Non |
| **Lui passer la balle** | Kick doux (phase 2) | Oui (config) |
| Cache-cache / 1-2-3 soleil | États de l'orchestrateur | Non — 1-2-3 soleil **fait** (avec les humains, 2026-10-05) |
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
  et passe en veille plutôt que de recommencer. **Fait (2026-10-05)** : 3 chutes en 10 min (chat ou autre) →
  veille assise de 15 min, sans se relever entre deux siestes.

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

**Rappel (principe directeur 6) : toutes les idées de cette sous-section
demandent du matériel ajouté → développées seulement après l'ensemble des
fonctions « robot seul ».**

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

### Mécanismes encore inexplorés

- **Joue avec sa propre ombre** : la repère au sol (lumière + mouvement),
  bouge pour voir si elle suit, petite insistance curieuse — gratuit et
  amusant à observer.
- **Hésitation visible entre deux stimuli intéressants simultanés** (la
  balle roule pendant que le chat traverse) : petit balancement de tête
  entre les deux avant de choisir, plutôt qu'une priorité rigide toujours
  identique.
- **Reconnaît une accroche audio récurrente de divertissement** (le
  jingle d'une émission suivie souvent à la même heure) : vient
  s'installer calmement pour « co-regarder », plutôt que son jeu
  habituel — une routine partagée plutôt qu'une réaction isolée.
- **Agitation discrète pendant une absence plus longue qu'à l'habitude**,
  *avant* le retour — pas la joie déjà prévue après, mais une petite
  nervosité/vérification répétée (va à la fenêtre, à la porte) si
  quelqu'un n'est pas rentré à l'heure attendue.
- **Offre spontanément son jouet favori à quelqu'un** : au-delà de
  « montrer une découverte » déjà noté, un vrai geste de don — vient
  déposer l'objet devant la personne comme une invitation à jouer.
- **Indice acoustique de la pièce** (écho/réverbération, pas seulement
  l'odométrie) pour deviner grossièrement la taille/le type de pièce →
  nuance discrètement le comportement (plus exploratoire dans une grande
  pièce qui résonne, plus posé dans une petite pièce feutrée).
- **Un geste signature rare**, pas plus d'une fois par jour, différent
  des initiatives habituelles déjà prévues (~6/h) — la rareté elle-même
  comme ingrédient, en écho direct au principe Pollen déjà noté (« un duo
  surprise est un plaisir, un juke-box non »).
- **Sensibilité à la tendance météo avant même l'alerte** : si HA donne
  une tendance de pression qui chute, léger changement d'humeur qui
  précède l'alerte officielle plutôt que d'attendre la notification.
- **Mini-jeu pierre-papier-ciseaux simplifié** : trois gestes de tête/bec
  distincts proposés par le robot, l'humain répond avec sa main devant
  la caméra — un vrai petit jeu dédié, à part du jeu de balle.
- **Dépit comique après un tir raté, puis regain de motivation** : au
  lieu d'un score plat, une petite réaction de frustration visible
  suivie d'un nouvel essai plus déterminé — donne un arc émotionnel à la
  partie plutôt qu'une série de tentatives identiques.
- **Fierté discrète s'il s'entend complimenter en parlant de lui** (« il
  est mignon » dit à un invité, pas adressé directement à lui) —
  distinct de la réaction au ton quand on l'appelle, ici il capte qu'on
  parle de lui en bien sans qu'on s'adresse à lui.
- **Petit geste gêné après un trébuchement devant quelqu'un** : au-delà
  du simple rattrapage physique déjà prévu, une touche sociale, comme
  s'il savait qu'on l'a vu rater son coup.
- **Curiosité méfiante prolongée envers un nouvel appareil domestique**
  (nouvelle enceinte, nouvel aspirateur) tant qu'il reste « nouveau » —
  plus marquée et plus longue qu'avec un simple objet déplacé, parce que
  celui-ci bouge/fait du bruit lui aussi.
- **Répertoire de tours sur demande** (salut, tour sur lui-même)
  déclenchés par un geste de la main plutôt qu'un ordre vocal, à
  distinguer des réflexes autonomes : ici il « obéit » volontiers à une
  demande claire, comme un animal qui fait un tour pour le plaisir de la
  relation, pas une initiative spontanée.
- **Note pour plus tard, pas un comportement en soi** : pendant qu'un
  mouvement RL est encore en cours d'affinage (checkpoint intermédiaire),
  le laisser tourner tel quel une fois devant vous — l'imperfection
  visible (petit déséquilibre qu'il corrige) donne involontairement une
  impression d'« effort », presque plus vivant qu'une version déjà
  parfaite.

### Occupation autonome et recherche d'attention

**Principe (2026-10-05) : si personne ne s'occupe de lui pendant un
moment, le robot ne reste pas simplement passif — il choisit, selon l'état
M9 du moment, soit de s'occuper lui-même seul, soit d'aller chercher
l'attention d'un humain ou du chat.** Les deux familles de comportement
ci-dessous (solitaire / recherche d'attention) sont les deux issues
possibles de ce principe, pas deux idées séparées.

- **S'ennuie visiblement si rien ne se passe pendant longtemps** —
  distinct du simple `Chill` calme : petits soupirs, regards qui errent,
  comme un animal qui cherche quoi faire, pas juste un état au repos.
- **Fatigue progressive visible à batterie faible** (ralentissement
  graduel des mouvements, pas une alerte binaire) — complète l'idée déjà
  notée « se recharge de sa propre initiative », mais ici c'est la
  dégradation du comportement lui-même qui se voit avant l'action.
- **Petit jeu solitaire quand personne n'est là** (pousse sa propre
  balle, s'amuse seul) — détecté par l'absence de présence HA/caméra,
  pour un contraste visible avec le jeu social, comme un animal qui
  s'occupe seul.
- **Va chercher activement l'attention d'un humain présent** s'il
  s'ennuie depuis un moment et qu'un habitant est détecté (HA ou
  caméra/ToF) — vient se placer près de lui, petit son d'appel, sans
  jamais insister au-delà d'une tentative (cohérent avec la règle « ne
  jamais insister »).
- **Va chercher l'attention du chat** si aucun humain n'est disponible
  mais que le chat est détecté — variante de la recherche d'attention,
  dirigée vers le seul autre « habitant » présent plutôt que vers du vide.
- **Mémorise et évite spécifiquement un point précis où il est déjà
  tombé**, pas juste l'évitement ToF générique — une vraie « zone noire »
  apprise, distincte d'un obstacle détecté à chaque fois.
- **Deux coins favoris distincts selon l'activité** (un pour
  observer/regarder la pièce, un autre pour vraiment se reposer) plutôt
  qu'un seul « spot favori » — nuance le comportement déjà prévu.
- **Boude légèrement après avoir été grondé** : une durée de
  froideur/retrait qui suit la réaction immédiate au ton (déjà prévue),
  pas juste l'instant où ça arrive.
- **Distingue le début de la pluie du bruit de pluie qui continue** — ne
  réagit qu'au changement d'état (son contre la fenêtre), pas à chaque
  instant où elle tombe, pour ne pas s'habituer à ignorer.
- **Petite vérification de son reflet le soir avant de s'installer** —
  complète le rituel « miroir qui évolue » déjà noté, mais ici un geste
  bref et récurrent, pas une réaction isolée.
- **Réagit à un objet qui tombe de son propre bec/pattes** (ce qu'il
  transportait) par une petite surprise + recherche au sol, distinct de
  la détection d'objets au sol en général.
- **S'arrête et marque une pause avant un passage étroit** (couloir)
  plutôt qu'un évitement ToF purement réactif — une prudence apprise sur
  ce type de passage précis.

### Taquineries envers les humains

Garde-fou commun à toute cette section : une taquinerie dure quelques
secondes, jamais plus, et **s'arrête au premier signe d'ennui réel**
(ton qui change, geste d'écart) — cohérent avec la règle « ne jamais
insister » déjà posée. L'objectif est l'amusement partagé, pas la
nuisance.

- **Vol et planque ludique d'un petit objet sans importance**
  (chaussette, petit jouet) : l'emporte, reste à distance en le montrant,
  puis s'échappe si on approche — un jeu du chat-et-la-souris, pas un
  vrai vol (distinct du « cache » déjà prévu pour `GroundPick`, ici
  explicitement joueur et face à un humain).
- **Imite en exagérant un geste qu'on vient de faire** — par exemple
  secouer la tête juste après qu'on lui a dit « non », comme s'il
  « répétait » de façon un peu moqueuse.
- **Se place brièvement en travers du chemin** de quelqu'un qui marche
  (jamais dans un escalier ni un passage à risque), puis s'écarte avec un
  petit son amusé — un courant d'air ludique, pas un obstacle réel.
- **Fait style de dormir quand on l'appelle**, puis bouge soudainement
  une fois qu'on a le dos tourné — faux-endormi classique chez un animal
  joueur.
- **Secoue la tête « non » à une demande de jeu, avant d'obéir quand même
  après un court délai** — résistance théâtrale et comique, jamais
  appliquée à une consigne de sécurité ou à un ordre sérieux, seulement
  au registre du jeu.
- **Mime le ton de voix de qui l'appelle**, de façon exagérée (intonation
  montante/descendante reproduite en son de canard, pas un vrai mot) —
  un petit effet « perroquet » ironique.
- **S'installe délibérément sur un objet qu'on cherche** (jouet, feuille
  de papier) comme pour s'amuser à être dessus — mini blocage ludique,
  se lève dès qu'on insiste un peu.
- **Fausse feinte avant un tir** (regarde ostensiblement une direction
  puis shoote dans une autre) — un clin d'œil « sportif », purement pour
  l'effet comique pendant une partie de balle.
- **Pousse un objet léger juste hors de portée** (stylo, balle en mousse)
  quand quelqu'un essaie de l'attraper — une ou deux fois, pas une
  boucle sans fin.
- **Suit exactement les pas de quelqu'un en miroir comique**, juste
  derrière, jusqu'à ce que la personne se retourne — jeu du « copycat ».
- **Petite course ludique sur un trajet court** (accélère légèrement pour
  arriver avant quelqu'un à la porte ou au canapé) — compétition
  amicale, pas une vraie gêne de passage.
- **Fait style de ne pas entendre un appel** (regarde ailleurs
  ostensiblement), puis réaction exagérée après coup — faux air distrait
  volontaire, distinct d'une vraie inattention.
- **Bâillement « sarcastique »** décalé et exagéré, sur un ton différent
  de la contagion sincère déjà notée — pour se moquer gentiment plutôt
  que par réflexe.
- **Prend la place convoitée** (s'installe sur le coussin/la chaise
  qu'on allait prendre) — transposition du « chat qui prend ta place ».
- **Petit détour volontaire dans les jambes** de quelqu'un qui marche,
  comme pour le ralentir un instant — à garder bref, jamais près d'un
  escalier ou les mains chargées.
- **Pousse doucement la main de quelqu'un qui tient un objet**, comme
  pour réclamer alors qu'il n'a besoin de rien — un geste espiègle
  plutôt qu'un vrai besoin, sans jamais faire perdre l'objet.
- **Photobombe** : se place entre la caméra d'un téléphone et le sujet
  qu'on essaie de photographier/filmer (détecte un téléphone pointé
  *ailleurs* que vers lui) — vol de vedette classique.
- **S'incruste dans les appels vidéo** : vient se placer dans le champ
  pendant un appel, comme s'il voulait « participer » — variante du
  photobombe, spécifique à l'écran plutôt qu'au téléphone.
- **Feinte affectueuse** : fait mine de donner un petit coup de bec
  tendre, puis dévie au dernier moment en s'écartant d'un bond — un
  « je t'aurai pas » joueur plutôt qu'un vrai refus.
- **Joue à se faire désirer avant la caresse** : esquive une fois la
  main qui s'approche (un pas de côté), puis se laisse caresser la fois
  suivante — jeu de la poursuite affectueuse, pas un vrai évitement.
- **Regard mystérieux vers un point vide** : fixe intensément un endroit
  sans rien de particulier, pour attirer l'attention, comme un chat qui
  regarde fixement le vide — gag pur, sans vraie alerte derrière.
- **A toujours le dernier mot** : répond systématiquement par un bref
  son de canard à chaque silence dans une conversation entre humains,
  comme s'il voulait participer sans jamais rien dire d'utile.
- **Running gag reconnu sur son propre numéro** : si la « planque
  d'objet » ci-dessus se répète souvent, un petit air content/fier
  distinct après coup — comme s'il savait que c'est devenu sa blague
  récurrente, pas juste un comportement isolé répété sans variation.
- **Compte les éternuements** : au-delà du premier (contagion sincère
  déjà notée), un petit bruit amusé et différent à chaque éternuement
  supplémentaire d'une même série — comme s'il « comptait » avec un brin
  de moquerie.
- **Fausse chute comique** (distincte du trébuchement « accidentel
  rattrapé » déjà en RL) : un mouvement clairement théâtral, pas une
  vraie perte d'équilibre, juste pour l'effet devant quelqu'un.
- **S'installe sur le tapis pendant une séance d'étirement/yoga au sol**
  — interrompt gentiment sans faire exprès... ou presque.
- **Fait style de « superviser »** un rangement en restant juste à côté
  sans rien faire, un peu encombrant — le chat qui regarde faire sans
  aider.
- **S'assoit sur l'outil/la pièce** pendant un bricolage (atelier CNC/
  impression 3D) — taquinerie du quotidien plutôt qu'un gag générique.
- **Vole le centre du cadre lors d'un selfie de groupe** — variante du
  photobombe, spécifiquement « au milieu ».
- **Garde un siège « juste trop tard »** : s'y installe une seconde
  avant que quelqu'un s'assoie, debout dessus un bref instant avant de
  laisser la place — variante plus comique de la place convoitée.
- **Parodie sonore d'une notification de téléphone**, pour faire réagir
  quelqu'un qui regarde ailleurs, puis s'enfuit content — à utiliser
  avec parcimonie et un son clairement ludique (jamais une imitation
  fidèle d'alarme), pour que ça reste drôle et jamais anxiogène.
- **Trophée de malice cumulé** : après plusieurs taquineries réussies
  (photobombe, planque d'objet…), un petit air fier distinct — une
  fierté qui se construit sur l'historique des blagues plutôt
  qu'identique à chaque fois.
- **Taquine le robot aspirateur activement** : lui bloque brièvement le
  chemin pour « jouer », au-delà de la simple curiosité/méfiance déjà
  notée — passe d'une relation passive à une vraie taquinerie entre les
  deux « habitants » non-humains.
- **Faux bâillement d'ennui** pendant une réunion ou une discussion qui
  s'étire — commentaire ironique sur la longueur, sans jugement réel du
  contenu.
- **Air mystérieux sans rien révéler** : hoche la tête d'un air entendu
  si quelqu'un cherche un objet longtemps — gag pur, jamais au détriment
  d'une vraie aide (s'il sait réellement où est l'objet, le comportement
  « montrer une découverte » déjà prévu prend le relai, pas la rétention
  malicieuse).
- **Petit ricanement bref si quelqu'un glisse sans se faire mal** —
  garde-fou fort : bascule immédiatement en inquiétude/retrait au
  moindre signe de douleur réelle, jamais de moquerie si ce n'est pas
  clairement anodin.

### Petits services rendus (pas que ludique)

- **Va chercher un objet désigné sur demande** (pantoufles, télécommande…) —
  service concret au-delà du jeu ou de la taquinerie.
- **Signale un robinet qui goutte ou de l'eau qui coule anormalement
  longtemps** — perception sonore tournée vers l'entretien du foyer, pas
  seulement vers le jeu ou la sécurité.
- **Rappelle une tâche oubliée via HA** (four resté allumé, lumière
  extérieure en plein jour…) en venant activement chercher la personne
  plutôt qu'une simple notification passive.
- **Aide à retrouver un objet perdu** via une mémoire visuelle passive du
  dernier endroit où il a été vu — extension utile de l'« air mystérieux »
  et du « montrer une découverte » déjà prévus, mais orientée service rendu.

### Comportement collectif (plusieurs personnes à la fois)

- **Mode festif distinct** quand plusieurs personnes sont réunies (repas,
  anniversaire) — virevolte entre les gens plutôt que de se fixer sur un
  seul.
- **Répartition de l'attention perçue comme équitable** entre plusieurs
  personnes présentes, pour éviter l'impression de favoritisme.

### Le monde extérieur vu de l'intérieur (fenêtre, jardin)

- **Observe les oiseaux ou un animal sauvage dans le jardin par la
  fenêtre**, avec curiosité — pendant depuis l'intérieur, complémentaire
  de la vigilance chat déjà prévue.
- **Anticipation visuelle d'une arrivée** (voiture qui se gare, quelqu'un
  qui approche à pied) avant même la sonnette ou le bruit de clés —
  perception proactive plutôt que réactive.

## Tableau — dépendance matérielle de chaque proposition

Légende :
- **Robot seul** : capteurs/calcul déjà embarqués (caméra, ToF, micro, IMU, NPU 0,8 TOPS du robot) — aucun appareil externe, achat ou non.
- **HA / réseau** : dépend de Home Assistant ou du réseau domestique déjà en place — pas de nouvel achat, mais pas autonome du robot seul.
- **Mixte** : combine robot seul et HA/réseau.
- **Matériel à ajouter** : nécessite un nouvel achat/accessoire physique (capteur dédié, tag, station, etc.).

Rappel (Phase 3) : toute case « Robot seul » qui suppose un vrai modèle de
reconnaissance (pas juste couleur/mouvement/niveau sonore) reste un
**candidat à trier une fois le NPU du robot profilé à la livraison** — voir
plus haut. Le tag ici dit *où ça tourne*, pas si c'est déjà garanti faisable.

### Pistes générales (haut de section)

| Proposition | Dépendance |
|---|---|
| Rythme circadien réel (M9 + heure du jour) | Robot seul |
| Petits rituels de présence (départ/retour) | HA / réseau |
| Mémoire des objets (au-delà des habitants) | Robot seul |
| Réaction à la musique/au rythme ambiant | Robot seul |
| Personnalité qui dérive avec l'usage | Robot seul |
| Vocalisations gratuites, sans fonction | Robot seul |
| Conscience du calendrier domestique | HA / réseau |
| Spot favori appris (pas imposé) | Robot seul |

### Réflexes autonomes déclenchés par l'environnement (son, vue)

| Proposition | Dépendance |
|---|---|
| Danse au rythme détecté au micro | Robot seul |
| Sursaut au bruit sec et fort | Robot seul |
| Réaction aux applaudissements | Robot seul |
| Rire détecté | Robot seul |
| Silence inhabituel à une heure bruyante | Robot seul |
| Son propre reflet (miroir, vitre) | Robot seul |
| Mouvement périphérique sans cible précise | Robot seul |
| Synchronisation sur quelqu'un qui danse | Robot seul |
| Bruit de clés dans la porte, avant ouverture | Robot seul |
| Bruit machine à café/bouilloire le matin | Robot seul |

### Actions spontanées vers l'humain

| Proposition | Dépendance |
|---|---|
| Tenir compagnie pendant une activité longue immobile | Mixte (présence HA + ToF/caméra) |
| Discrétion automatique pendant un appel téléphonique | Robot seul |
| Réagir à son prénom entendu | Robot seul |
| Anticiper la caresse (main qui s'approche) | Robot seul |
| Contagion du bâillement | Robot seul |
| Timidité initiale avec un visiteur inconnu | Robot seul |
| Présence silencieuse si ton de voix triste | Robot seul |
| Rejoindre la pièce à vivre à l'heure des repas | Robot seul (HA utile en option) |

### Sommeil et réveil

| Proposition | Dépendance |
|---|---|
| « Rêves » pendant la charge/veille nocturne | Robot seul |
| S'ébroue après une longue immobilité réelle | Robot seul |

### Exploration et curiosité

| Proposition | Dépendance |
|---|---|
| Cherche le soleil (zone de lumière forte) | Robot seul |
| Remarque un objet qui n'était pas là avant | Robot seul |
| Ramasse/cache/promène un objet (`GroundPick`) | Robot seul |
| Vient « montrer » une découverte | Mixte (HA utile pour localiser l'habitant) |

### Ambiance du foyer et évolution dans le temps

| Proposition | Dépendance |
|---|---|
| Se retire si l'ambiance est très bruyante/chaotique | Robot seul |
| Réagit différemment aux bips des autres appareils | Robot seul |
| Rythme différent semaine/week-end | Robot seul |
| Personnalité un peu saisonnière (météo) | HA / réseau |
| Motif sonore personnel qui dérive avec le temps | Robot seul |

### Interaction avec le reste de la maison

| Proposition | Dépendance |
|---|---|
| Curiosité/méfiance envers le robot aspirateur | Robot seul |
| Va se recharger de sa propre initiative | Robot seul |
| Anticipe un orage annoncé | HA / réseau |

### Préférences et apprentissage non programmé

| Proposition | Dépendance |
|---|---|
| Jouet favori appris (par historique de jeu) | Robot seul (moins fiable sans NFC — voir Pistes physiques) |
| Mot/son déclencheur qui émerge par répétition | Robot seul |

### Conscience de l'environnement et de lui-même

| Proposition | Dépendance |
|---|---|
| Toilette après activité poussiéreuse (CNC, impression) | Robot seul |
| Réagit au fait d'être photographié/filmé | Robot seul |
| Baisse vitesse/volume la nuit (lumière ambiante) | Robot seul |
| Petit geste d'au revoir en écho au ton habituel | Robot seul |

### Sécurité et urgence perçue

| Proposition | Dépendance |
|---|---|
| Alarme incendie / détecteur de fumée | Robot seul |
| Sonnette vs coup à la porte | Robot seul |
| Feux d'artifice/pétards (distinct du tonnerre) | Robot seul |

### Nuances sociales plus fines

| Proposition | Dépendance |
|---|---|
| Distingue le ton en entendant son prénom (gronder/câliner) | Robot seul |
| Visiteur récurrent reconnu comme tel | Robot seul |
| Cherche la présence humaine plutôt que la prise | Robot seul |
| Salutation sonore individualisée par habitant | Robot seul |

### Initiative de jeu, pas seulement réaction

| Proposition | Dépendance |
|---|---|
| Lance lui-même une partie de cache-cache | Robot seul |
| Cherche activement son jouet favori disparu | Robot seul |

### Décor visuel et auto-préservation

| Proposition | Dépendance |
|---|---|
| Décorations saisonnières détectées à la vue | Robot seul |
| Réaction distincte neige vs pluie par la fenêtre | Robot seul |
| Re-explore après un réaménagement du mobilier | Robot seul |
| Auto-préservation thermique (température servos) | Robot seul |

### Nuances sociales et comportementales supplémentaires

| Proposition | Dépendance |
|---|---|
| Toast / geste collectif (verre levé) | Robot seul |
| Vérifie le chat s'il arrête soudainement de miauler | Robot seul |
| Jeu de « chaud/froid » improvisé par intonation | Robot seul |
| Découragement progressif plutôt que tout-ou-rien | Robot seul |
| Observe en silence une activité manuelle minutieuse | Robot seul |
| Rituel face au miroir qui évolue avec le temps | Robot seul |
| Distingue chahut joueur et vraie dispute | Robot seul |

### Pistes physiques (matériel autour du robot)

Cette sous-section du ROADMAP liste elle-même des accessoires physiques —
toutes ces lignes sont donc, par construction, du **Matériel à ajouter**.

| Proposition | Dépendance |
|---|---|
| Jouet sonore (haut-parleur/grelot intégré) | Matériel à ajouter |
| Tags NFC dans les jouets | Matériel à ajouter |
| Tapis de pression / tag NFC au sol près de l'entrée | Matériel à ajouter |
| Station de recharge avec repère lumineux actif | Matériel à ajouter |
| Petite station météo extérieure connectée | Matériel à ajouter |
| Zone de repos dédiée et reconnaissable (tapis texturé) | Matériel à ajouter |
| Accessoire décoratif amovible (foulard, autocollant) | Matériel à ajouter (zéro électronique) |

### Mécanismes encore inexplorés

| Proposition | Dépendance |
|---|---|
| Joue avec sa propre ombre | Robot seul |
| Hésitation entre deux stimuli intéressants simultanés | Robot seul |
| Reconnaît une accroche audio récurrente de divertissement | Robot seul |
| Agitation discrète pendant une absence plus longue qu'à l'habitude | HA / réseau |
| Offre spontanément son jouet favori à quelqu'un | Robot seul |
| Indice acoustique de la pièce (écho/réverbération) | Robot seul |
| Un geste signature rare (≤1×/jour) | Robot seul |
| Sensibilité à la tendance météo avant l'alerte | HA / réseau |
| Mini-jeu pierre-papier-ciseaux simplifié | Robot seul |
| Dépit comique après un tir raté, puis regain | Robot seul |
| Fierté discrète s'il s'entend complimenter | Robot seul |
| Petit geste gêné après un trébuchement devant quelqu'un | Robot seul |
| Curiosité méfiante prolongée envers un nouvel appareil | Robot seul |
| Répertoire de tours sur demande (geste de la main) | Robot seul |
| Laisser tourner un mouvement RL imparfait tel quel | Robot seul |

### Occupation autonome et recherche d'attention

| Proposition | Dépendance |
|---|---|
| S'ennuie visiblement si rien ne se passe pendant longtemps | Robot seul |
| Fatigue progressive visible à batterie faible | Robot seul |
| Petit jeu solitaire quand personne n'est là | Robot seul |
| Va chercher activement l'attention d'un humain présent | Mixte (HA utile pour la présence) |
| Va chercher l'attention du chat si aucun humain n'est disponible | Robot seul |
| Mémorise et évite un point précis où il est déjà tombé | Robot seul |
| Deux coins favoris distincts selon l'activité | Robot seul |
| Boude légèrement après avoir été grondé | Robot seul |
| Distingue le début de la pluie du bruit de pluie qui continue | Robot seul |
| Petite vérification de son reflet le soir avant de s'installer | Robot seul |
| Réagit à un objet qui tombe de son propre bec/pattes | Robot seul |
| S'arrête et marque une pause avant un passage étroit | Robot seul |

### Taquineries envers les humains

Toutes ces idées s'appuient sur les capteurs déjà embarqués (vision, audio,
mémoire interne) — aucune n'a besoin d'un appareil externe.

| Proposition | Dépendance |
|---|---|
| Vol et planque ludique d'un petit objet | Robot seul |
| Imite en exagérant un geste qu'on vient de faire | Robot seul |
| Se place brièvement en travers du chemin | Robot seul |
| Fait style de dormir, bouge une fois le dos tourné | Robot seul |
| Secoue la tête « non » avant d'obéir quand même | Robot seul |
| Mime le ton de voix de qui l'appelle | Robot seul |
| S'installe délibérément sur un objet qu'on cherche | Robot seul |
| Fausse feinte avant un tir | Robot seul |
| Pousse un objet léger juste hors de portée | Robot seul |
| Suit les pas de quelqu'un en miroir comique | Robot seul |
| Petite course ludique sur un trajet court | Robot seul |
| Fait style de ne pas entendre un appel | Robot seul |
| Bâillement « sarcastique » | Robot seul |
| Prend la place convoitée | Robot seul |
| Petit détour volontaire dans les jambes | Robot seul |
| Pousse doucement la main de quelqu'un | Robot seul |
| Photobombe (téléphone pointé ailleurs) | Robot seul |
| S'incruste dans les appels vidéo | Robot seul |
| Feinte affectueuse (coup de bec dévié) | Robot seul |
| Joue à se faire désirer avant la caresse | Robot seul |
| Regard mystérieux vers un point vide | Robot seul |
| A toujours le dernier mot (silence de conversation) | Robot seul |
| Running gag reconnu sur son propre numéro | Robot seul |
| Compte les éternuements | Robot seul |
| Fausse chute comique (distincte du vrai trébuchement) | Robot seul |
| S'installe sur le tapis pendant une séance d'étirement | Robot seul |
| Fait style de « superviser » un rangement | Robot seul |
| S'assoit sur l'outil/la pièce pendant un bricolage | Robot seul |
| Vole le centre du cadre lors d'un selfie de groupe | Robot seul |
| Garde un siège « juste trop tard » | Robot seul |
| Parodie sonore d'une notification de téléphone | Robot seul |
| Trophée de malice cumulé | Robot seul |
| Taquine le robot aspirateur activement | Robot seul |
| Faux bâillement d'ennui | Robot seul |
| Air mystérieux sans rien révéler | Robot seul |
| Petit ricanement bref si quelqu'un glisse sans se faire mal | Robot seul |

### Petits services rendus (pas que ludique)

| Proposition | Dépendance |
|---|---|
| Va chercher un objet désigné sur demande | Mixte (reco objet embarquée + commande vocale Wyoming/HA) |
| Signale un robinet qui goutte / eau qui coule anormalement | Robot seul |
| Rappelle une tâche oubliée via HA (four, lumière) | HA / réseau |
| Aide à retrouver un objet perdu (mémoire visuelle) | Robot seul |

### Comportement collectif (plusieurs personnes à la fois)

| Proposition | Dépendance |
|---|---|
| Mode festif distinct à plusieurs personnes réunies | Robot seul |
| Répartition de l'attention perçue comme équitable | Robot seul |

### Le monde extérieur vu de l'intérieur (fenêtre, jardin)

| Proposition | Dépendance |
|---|---|
| Observe les oiseaux/un animal sauvage dans le jardin | Robot seul |
| Anticipation visuelle d'une arrivée (voiture, pas) | Robot seul |

### Bilan rapide

Sur l'ensemble des propositions listées dans « Pistes supplémentaires » :
l'immense majorité (plus de 9 sur 10) tient sur le robot seul (vision
simple, audio, IMU, mémoire interne) ou sur Home Assistant déjà en place —
sans aucun nouvel appareil à acheter. Seule la sous-section « Pistes
physiques » (jouet sonore, tags NFC, station météo, tapis de repos, décor)
suppose explicitement du matériel ajouté, et reste par construction en
Phase 4 « plus tard », pas dans le chantier actif.

## Application Microduck (téléphone, sans Home Assistant) — décidé le 2026-10-06

Une **application à part entière pour gérer le canard**, indépendante de Home Assistant (HA reste un complément pour
la maison). Elle n'a pas de serveur ailleurs : **c'est le canard qui la sert**, sur le réseau local.
- Sur le téléphone, on l'ouvre une fois dans le navigateur, puis « Ajouter à l'écran d'accueil » : elle s'ouvre alors
  comme une appli, avec son icône (application web installable, PWA).
- Rien n'est installé sur le téléphone.

**Règles** :
- Le téléphone **affiche des états et envoie des commandes**. Il n'analyse rien, et ne reçoit ni image ni son.
- L'accès est protégé par un **code d'appairage** défini dans `ha.toml` (`[appli]`), et réservé au réseau local.
- Une vue caméra éventuelle ne viendrait que plus tard, en option explicite (vie privée).

**Sections** :

| Section | Contenu |
|---|---|
| Accueil | Ce qu'il fait, son humeur (énergie, éveil), sa batterie, qui est à la maison, son journal du jour |
| Jouer | Balle, cache-cache, 1-2-3 soleil, fin du jeu ; tours : salut, toupie, assis/debout, danse |
| Télécommande | Tête ; petits pas guidés (avancer, tourner) passés **par le cerveau**, avec les mêmes garde-fous : capteur de distance obligatoire, jamais vers un vide, pas de recul à l'aveugle ; arrêt immédiat |
| Maintenance | **Lancer le diagnostic** ; dernier résultat détaillé ; batterie (niveau, tension, santé, autonomie, cycles) ; servos (dérives, servo le plus chaud) ; chutes (7 jours, lieux à risque) ; températures ; version du cerveau |
| Caractère et mémoire | Traits de personnalité, voix (ses sons préférés), habitants et familiarité, blagues, coins appris |
| Réglages | Mode calme, mode garde, couper les taquineries |
| Journal | Les derniers états et événements, pour comprendre ce qu'il a fait |

**État : v1 faite (2026-10-06)**, vérifiée par des tests et rendue dans un navigateur au format téléphone, en thème
clair et sombre ; pas encore essayée avec le canard.
- `appli.py` : serveur intégré à `canard.py`, sans dépendance nouvelle.
- `interface/` : HTML, CSS et JS sans framework.
- Les 7 sections ci-dessus sont en place. Le diagnostic se lance à la main (bouton aussi présent dans HA).
- La télécommande passe par le cerveau : `PasGuide`, `RegardGuide`.
- À valider avec `duck-sim` (`[appli] code` dans `ha.toml`, puis `http://127.0.0.1:8090`), puis sur le robot.
- Limite connue : en HTTP sur le réseau local, le navigateur n'active pas le mode hors ligne (il faudrait HTTPS).
  L'ajout à l'écran d'accueil fonctionne quand même.
- **APK Android** (`microduck-brain/android/`, 2026-10-06) : coquille plein écran autour de l'interface du canard,
  aucune logique dedans (une mise à jour du cerveau met l'appli à jour).
  - Trouve le canard seule : elle interroge `/api/sante` sur le port 8090 de tout le sous-réseau du téléphone.
  - Sinon, adresse à taper (mémorisée).
  - **Mode démo** (`interface/demo.js`, canard imaginaire) pour l'essayer sans le robot.
  - Construite sans Android Studio : `bash android/construire.sh` (paquets Ubuntu `aapt`, `dalvik-exchange`,
    `apksigner`…). Clé de signature hors du dépôt (`~/.microduck-android/`).
  - Logo de l'appli : `outils/logo.png` → `outils/icone_logo.py`.
  - À tester sur le téléphone : la démo d'abord, puis contre le canard.
- **Carte des zones** (accueil, APK 0.2) : dessinée **par le canard lui-même**, sur le robot, à partir de sa mémoire
  d'exploration (`exploration.py`).
  - Odométrie de `robotd` → cases de 25 cm traversées.
  - ToF → obstacles ; chutes → zones noires.
  - Coins favoris (sieste, repos, repas), chargeur appris, objets remarqués.
  - `GET /api/carte`, recalculée toutes les 3 s.
  - Limites : odométrie seule, donc la carte **repart de zéro à chaque démarrage** et dérive avec la distance. Ce
    n'est pas un SLAM.
  - Bouton « Effacer sa carte » (Réglages) : meubles déplacés, autre pièce.
- **Lieux** (`lieux.py`, APK 0.3, fait le 2026-10-06) : le canard reconnaît où il est **par son Wi-Fi**.
  - Le Wi-Fi est lu sur le canard (`iwgetid`, `wpa_cli` ou `nmcli`), toutes les 30 s, dans un fil à part.
  - Réseau inconnu vu 2 fois de suite → « Nouveau lieu » : il le crée, y bascule, et devient curieux. Retour sur un
    réseau connu → il y rebascule et s'étire. Pas de Wi-Fi → il ne bouge pas.
  - Chaque changement de lieu : nouvelle carte. La dernière carte du lieu quitté est gardée pour être regardée dans
    l'appli.
  - Dans l'appli (Réglages → Lieux) :
    - « Y aller », renommer, nouveau lieu ;
    - lier le Wi-Fi actuel à un lieu (répéteur, ou un lieu créé à la main) ;
    - bascule automatique oui/non par lieu (non : il le propose au lieu d'y aller) ;
    - archiver (rangé, mais reconnu s'il y retourne), restaurer, supprimer.
  - Fichier local `lieux.json` à côté de la mémoire ; `lieux = false` dans `[cerveau]` pour couper.
  - **À valider sur le robot** : quel outil lit le Wi-Fi sur son système (iwgetid, wpa_cli, nmcli…). Il faudra
    aussi lui donner le Wi-Fi des parents avant d'y aller.
  - **Plus tard**, quand la carte sera gardée d'un jour à l'autre (balises UWB, recalage sur le chargeur) : la
    réutiliser pour naviguer dans un lieu connu (coins, chargeur, zones noires).

- **Design space** (icône palette en haut à droite, 2026-10-06) : le vrai Microduck en 3D, à recolorer avant
  d'imprimer.
  - Modèle officiel allégé (`outils/modele_3d.py` : 112 000 triangles, 1,3 Mo, 19 groupes de pièces). three.js est
    embarqué : aucun CDN.
  - Toucher une pièce, nuancier (« mes filaments » + palette), couleur libre, comparer avec l'origine, schémas
    nommés gardés sur le canard (`/api/design`).
  - **STL perso** : dessiné à partir du STL d'origine, dans le même repère, il se pose exactement à sa place
    (mm ou m détectés).
- **Marketplace** (icône sac) + dépôt public
  [`microduck-catalogue`](https://github.com/RaphaelGrj/microduck-catalogue).
  - Une fiche `fiche.toml` et des photos par pièce, ajoutées depuis github.com.
  - Un GitHub Action vérifie les fiches et fabrique `catalogue.json`.
  - L'appli montre les pièces, ouvre Printables/Cults dans le navigateur, et « Essayer sur mon Microduck » pose
    l'aperçu STL dans le design.
  - C'est le téléphone qui lit le catalogue, pas le canard.
- **Alertes et notifications** :
  - Le canard tient ses alertes (`/api/alertes`) : chute, batterie faible, diagnostic en échec, garde, incendie,
    impressions et machines.
  - L'APK les notifie toutes les 15 min en arrière-plan (minimum d'Android), et tout de suite quand l'appli est
    ouverte.
- **Ses 3 batteries** : après un échange, l'appli demande laquelle est mise ; cycles, autonomie et santé par batterie.
- **Réglages → Sa journée** (heures calmes, bonjour, repas, auto-test, rythme) : `reglages.json` prend le dessus sur
  `ha.toml`, appliqué sans redémarrer.
- **Sa semaine** (Journal) : historique des jours dans la mémoire (60 jours).
- **Widget Android** : son état et sa batterie.
- **Écarté** : l'appairage par QR code. Le canard n'a pas d'écran, et l'appli le trouve déjà seule sur le Wi-Fi ;
  le code ne se tape qu'une fois.

- **APK 0.8 (2026-10-06)** :
  - **Où es-tu ?** : trois `chirp`, pas en mode calme.
  - **Son look** : l'accueil prend les couleurs du schéma actif, pose par pose.
  - **Fiche d'impression** (couleur → pièces → STL d'origine) et **photo** 4:3 dans le design.
  - **Mise en route** : liste du jour de la livraison, cochée seule quand c'est vérifiable.
  - **Routines** programmées.
  - **Sauvegarde et restauration** de sa mémoire (jamais `ha.toml`).
  - **Présence par le téléphone** : seulement l'arrivée, le départ reste à Home Assistant.
  - **Mise à jour de l'APK** proposée (`android/version.json`).
  - **À changer quand la branche sera fusionnée** : l'adresse de mise à jour pointe sur la branche
    `ccr-4c5851c0-mdd2p8` (`Accueil.DEPOT`).

**Plus tard** :
- vue caméra en option (image envoyée au téléphone : à arbitrer avec la règle « rien ne sort du canard ») ;
- son « look » (schéma actif du design) sur l'image de l'accueil ;
- notifications instantanées en arrière-plan (service permanent) si 15 min s'avèrent trop longues.

## Tableau de synthèse

État au 2026-10-06 (soir). « Codé » = écrit et testé sans robot, à valider dans `duck-sim` puis sur le robot.

| Compétence | Officielle ? | Apport vivant / autonome | Effort | État |
|---|---|---|---|---|
| Marche + relevé | Oui | Socle de l'autonomie | Moyen | Officiel ; StandUp évalué (~100 %), arrêté : robotd se relève déjà |
| Gestes expressifs | Non | ★★★ personnalité | Faible | Fait (gestes scriptés, sans RL) |
| Regard / suivi de tête | Commande existante | ★★★ présence | Logiciel | Fait (`robot.look`, balle, chat) |
| Cerveau du foyer (aligné M9) | Non (M9 non porté) | ★★★ autonomie | Élevé | Codé : les 16 états M9 ; personnalité, taquineries, diagnostic ; 277 tests |
| Détection ballon + chat | — | ★★★ perception | Moyen | Fait en simulation (HSV, YOLOv8n) ; NPU du robot à étudier |
| Balle avec vision + passe douce | Kick oui, vision non | ★★★ jeu (moi + chat) | Élevé | Approche + tir validés en simulation ; tir gauche tolérant et passe douce à finir (GPU) |
| Home Assistant (dans les deux sens) | Non | ★★★ membre du foyer | Moyen | Codé : événements de la maison, entités du canard, scènes déclenchées par le canard, voix locale |
| Assis / repos | Oui | ★★ rythme de vie | Nul | Fait (`sit_toggle`) |
| Ramassage au sol | Oui | ★★ objets | Faible–moyen | Utilisé en mime (`ground_pick`) ; ce qu'il saisit vraiment est à voir sur le robot |
| Roulade, rollers | Oui | ★ spectacle | Nul | Disponible (`robot.do`) |

## Prochaines actions

État au 2026-10-06 (soir) : tout ce qui pouvait être codé sans robot ni simulateur l'est. La suite demande le PC (WSL)
puis le robot.

1. **Validation groupée sur le PC** : `git pull` de la branche dans `~/microduck-brain`, puis
   `setsid bash ~/microduck-brain/scripts-wsl/valider-tout.sh > /dev/null 2>&1 < /dev/null &` (~45 min). Il lance les
   tests, le banc de coût et 13 scénarios dans `duck-sim`, en commençant par `bec_index`. Renvoyer le rapport
   `~/validation-*.txt` à Claude.
2. **Home Assistant** :
   - reporter dans `ha.toml` les nouvelles sections de `ha.exemple.toml` : `[[action]]`, calendrier, température,
     visiteur, compagnie, repas, garde ;
   - vérifier avec `pont_ha.py ha.toml --verifier` ;
   - installer Mosquitto si tu veux le MQTT ;
   - installer l'intégration PrusaLink pour les Prusa.
3. **GPU, quand le PC est libre** : finir le tir tolérant du pied gauche (depuis 1 750), puis la passe douce
   (`~/kick_reprise.txt`).
4. **À la livraison du robot** :
   - lancer `bench_cerveau.py` sur le robot ;
   - appliquer les patchs `contrib/robotd-audio-*.patch` (micro partagé) ;
   - déployer avec `deploy/robot/` ;
   - étudier le NPU (détection de personnes) ;
   - étalonner les seuils audio et la caresse.

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

### 2026-10-05 — session cloud (sans GPU), "Occupation autonome" codé et testé
Session Claude Code dans le cloud (pas d'accès au PC/GPU de l'utilisateur, consigne explicite) : avance uniquement le
comportemental pur de `microduck-brain` (`brain.py`, `exploration.py`, `pont_ha.py`), rien côté `microduck_rl`/RL.
16 commits (`microduck-brain` : `97e60fb`, `f9da070`, `a5dc2df`, `3ec1d95`, `9afa476`, `d16cc67`, `7bf770a`,
`dbeaba1`, `9981a2f`, `e702362`, `b872fbf`, `fe59556`, `f39d491`, `7f6f824`), suite complète de tests passante
(27 tests `test_brain.py` + `test_exploration.py` + `test_ha.py`, dont un test d'intégration longue simulation
combinant plusieurs fonctions à la fois).

- **"Occupation autonome et recherche d'attention" implémenté** (section ROADMAP ajoutée plus tôt la même session) :
  `JeuSolitaire` et `RechercheAttention` (classes `Etat`) — au-delà de `SEUIL_ENNUI_S` (10 min) sans interaction, le
  canard ne reste pas passif en `chill` : il joue seul si personne n'est disponible, ou va chercher l'attention d'un
  habitant présent (présence HA) ou du chat (veille caméra), jamais plus souvent que `DELAI_ENNUI_S` (règle « ne
  jamais insister »). `Brain.presents` (suivi retour/départ) et `Brain.derniere_interaction` ajoutés.
- **2 bugs préexistants trouvés et corrigés dans `brain.py`** (confirmés via `git stash` sur `94855d5`, aucun lien
  avec le code ajouté ci-dessus) : `Wander.entre()` plantait (`KeyError: 'odom'`) sur un état sans `"odom"` ; et
  `self.tombe` ne pouvait jamais se réinitialiser dans les tests faute de champ `"policy"` dans l'état factice de
  `test_brain.py` (corrigé côté fixture de test, pas côté logique réelle — `robotd` fournit toujours ce champ).
- **Zone noire apprise au point de chute** (`exploration.py`) : `Exploration.chute(x, y, t)` mémorise la case où le
  canard est tombé (oubli très lent, ~1 mois), traitée comme un obstacle par `nouveaute()`/`meilleur_ecart()` — donc
  `Wander` l'évite déjà sans changement côté `brain.py` à part noter la dernière position odom connue au moment de
  la chute.
- **Rêves pendant la sieste profonde** (`Nap`) : 0 à 2 petits tressaillements de tête très faibles, jamais pendant
  l'endormissement (< 2 s) ni le réveil (4 dernières s) — pure code, aucun capteur/RL supplémentaire.
- **Petit rituel de présence au départ** (`"depart:Nom"`, symétrique de l'accueil au retour déjà existant) : signe
  discret (geste "oui" + chirp), jamais pendant la sieste/calme/une conversation en cours.
- **Fatigue progressive visible** (`fatigue(brain)`) : amplitude et cadence du mouvement de tête (`LookAround`)
  réduites à basse énergie, jamais vx/vyaw — qui doivent rester au-dessus de la zone morte de la marche
  (`ZONE_MORTE.md` : vx ≥ 0,3, |vyaw| ≥ 1,2), sous peine de jambes figées malgré la commande envoyée.
- **Coin favori appris, distinct par activité** (`Exploration.preference`/`coin_favori`) : mémoire longue (oubli en
  quelques jours) du temps cumulé passé en chill/nap par case, séparée de la novelty grid (oubli 10 min). **Limite
  assumée** : pas encore de navigation vers le coin appris — `brain.py` ne sait commander que vx/vy/vyaw et un cap
  d'exploration, pas se déplacer vers un point connu d'avance (même limite que `Accueil`) ; c'est une mémoire
  exploitable plus tard, pas encore un comportement de déplacement visible.
- **Pause visible avant un passage étroit** (`Wander`) : couloir < 0,5 m des deux côtés détecté par le ToF déjà
  câblé → pause de 0,6 s avant de s'y engager, une seule fois par traversée — prudent, pas un évitement.
- **S'ébroue après une longue immobilité RÉELLE, pas sur minuterie** : suit l'odom plutôt que l'horloge (fenêtre
  qui se redémarre à chaque vrai déplacement > 10 cm), déclenche le geste `ebouriffe` existant depuis un état de
  repos (chill/look) seulement — jamais pour interrompre une autre activité.
- **Murmure sonore occasionnel pendant les rêves** (Nap) : complète le tressaillement de tête déjà codé, silencieux
  automatiquement en mode calme (règle déjà en place pour tous les sons).
- **Test d'intégration** : une simulation longue (900 s, départ + retour + chute + ennui dans la même run) vérifie
  que toutes les fonctions ajoutées cette session ne s'interfèrent pas entre elles.
- **Va se recharger de sa propre initiative sur batterie réelle basse** (`Brain.BATTERIE_BASSE_PCT = 25.0`,
  `_batterie_pct` lu depuis `state["battery"]["percent"]`) : bascule en `nap` dès que la vraie batterie descend sous
  le seuil, en plus du déclencheur existant sur l'énergie comportementale simulée (`humeur.energie`) — les deux
  conditions sont indépendantes (`or`), aucune n'écrase l'autre. **Limite assumée** : « se recharger » veut dire ici
  se mettre au repos (`nap`), pas se déplacer physiquement vers une station de charge — même limite de navigation
  que `coin_favori`/`Accueil`, pas de contrôleur point-à-point dans `brain.py`.
- **« Reculer s'il approche vite » implémenté** (table « Le chat », déjà listée RL=Non) : `RegardeChat` suit
  maintenant la distance au chat (estimation sol de `chat.py`, repère du tronc) en plus du regard — une approche
  rapide (> 0,3 m/s de fermeture) sous un seuil de proximité (0,35 m) déclenche un petit pas en arrière d'1 s
  (vx = -0,35, au-dessus de la zone morte en valeur absolue) puis arrêt ; jamais une fuite continue, jamais
  déclenché par une visite normale (approche lente, même très proche).
- **« Chat vu au salon » remonté dans Home Assistant** (table « Le robot dans la maison (HA) ») :
  `PontHA.photographier` lit la veille caméra du chat (`chat.py`) quand elle est branchée au cerveau, publie
  `binary_sensor.microduck_chat_vu` (on/off) avec un attribut « depuis quand il est parti » mémorisé à chaque
  disparition — absence de veille caméra (cas des tests qui n'en branchent pas) traitée comme « non vu », jamais
  un plantage.
- **« Heures calmes » nocturnes optionnelles implémentées** (table « Humains », routine « Heure, HA » →
  États Stretch/Nap) : `Brain(heures_calmes=(debut, fin), horloge=...)` — synthétise les mêmes événements
  `calme_on`/`calme_off` que l'interrupteur Home Assistant pendant la plage configurée (ex. 23h-7h), réutilisant
  tout le chemin déjà testé plutôt que de le dupliquer. **Opt-in** : `heures_calmes=None` par défaut, aucun
  changement de comportement pour un cerveau qui ne le configure pas ; un toggle HA manuel pendant la nuit reste
  respecté jusqu'au prochain changement d'heure.
- **Reste à faire** (pistes « Robot seul » encore non codées) : « boude après réprimande » — bloqué, aucune
  détection de ton de voix existante dans le projet (hors scope d'une session sans micro/pipeline audio) ; faire
  effectivement se déplacer le canard vers son coin favori une fois une navigation-vers-un-point disponible ;
  tout ce qui dépend d'une analyse audio (rythme, applaudissements, rire, ton de voix) — aucun pipeline micro/FFT
  n'existe encore dans le projet, à construire avant de coder ces réflexes.
- **Dernier ajout de la session (après coupure 16h20 initiale, poursuite courte)** : `sensor.microduck_eveil`
  et `sensor.microduck_habitants_presents` publiés dans Home Assistant (l'éveil et la présence des habitants
  n'étaient suivis qu'en interne jusque-là).

### 2026-10-05, après-midi/soir — session cloud (suite) : les 6 « prochaines étapes » codées et testées

Toujours sans GPU ni robot (`microduck-brain` uniquement, branche `ccr-4c5851c0-mdd2p8`). **95 tests unitaires** passent
(`test_brain`, `test_exploration`, `test_ha`, `test_chat`, + nouveaux `test_main_tendue`, `test_caresse`, `test_soleil`,
`test_navigation`, `test_canard`, `test_audio`). Tous les nouveaux modules compilent en Python 3.11 (Pi OS Bookworm).
Rien n'a été essayé contre `duck-sim` (pas de simulateur dans le cloud) : **première chose à faire sur le PC**.

- **Routine du matin** (étape 6) : `Brain(bonjour=(7, 30))` — une fois par jour, dans les 4 h qui suivent l'heure, dès
  qu'il est au repos et hors calme : étirement + bonjour (« greet » seulement si un habitant est là). Section
  `[cerveau]` de `ha.toml` (`heures_calmes`, `bonjour`), enfin branchée au lancement. Bug d'ordre trouvé par le test
  (le bonjour passait avant un `calme_on` en attente) et corrigé.
- **Messager étendu** (étape 3) : `[[appareil]]` dans `ha.toml` — sonnette (`binary_sensor` ou `event.*`), machine
  connectée (états `finished`/`end`…), **appareil « bête » sur prise à mesure de puissance** (fini = sous le seuil
  pendant 3 min après un vrai cycle de 5 min ; les pauses de trempage ne déclenchent rien). **Si personne n'est à la
  maison, le canard garde le message et le redit à l'accueil du prochain retour** (`sensor.microduck_messages`). Le
  « vient te voir là où tu es » attend toujours une position de l'habitant.
- **Main tendue** (étape 2, `main_tendue.py`) : un objet qui *apparaît* à 4–30 cm devant un canard immobile (pas un
  meuble déjà là), tenu 0,25 s → il la regarde (`robot.look`) et la picore (coups de tête + « peck »), chirp quand elle
  part. Seulement en `chill`, tête immobile depuis 1 s (sinon un meuble « apparaît » quand la tête tourne — défaut
  trouvé en relisant), jamais si le chat est visible, une fois par 20 s. Corps immobile (zone morte).
- **Caresse** (étape 1, `caresse.py`) : sans attendre `pet-detect`, une main posée sur la tête **déplace les servos de
  tête** : consigne immobile depuis 1 s → position de repos mesurée → écart > 0,06 rad tenu 0,3 s = caresse. État
  `caresse` (Petted M9) : roucoulement, tête appuyée contre la main, trémoussement ; en sieste, un roucoulement sans se
  réveiller. L'événement `caresse` reste ouvert à `pet-detect`. **Hypothèse à vérifier sur le robot** : les XL330 de
  la tête cèdent-ils vraiment de plus de 3° sous une caresse ?
- **1-2-3 soleil** (étape 4) : `mouvement.py` (différence d'images 90×160, seuil + ouverture morphologique ; ignore
  bruit du capteur et changement de lumière ; ~13 ms/image sur PC, caméra analysée **seulement pendant le jeu**) +
  état `soleil` : demi-tour, compte en chirps à rythme variable, se retourne, regarde 3,5 s ; mouvement → alarme +
  « non » ; joueur à < 30 cm (ToF) ou caresse → gagné (wheee + trémoussement). Défaut trouvé en traçant : chaque
  demi-tour s'arrêtait à 160° dans le même sens → 40° de dérive par manche ; corrigé par des caps absolus (le joueur,
  puis le dos au joueur). Lancement : boutons MQTT `button.microduck_jouer_soleil` / `fin_jeu`, ou `[[declencheur]]`
  générique (n'importe quelle entité HA → n'importe quel événement du cerveau). Taquinerie (registre du jeu) : 1 fois
  sur 5, « non » théâtral avant de jouer quand même.
- **Navigation vers un point** (`navigation.py`, « hors de portée » levé en partie) : pivote jusqu'à 10° du cap, marche
  droit, re-pivote au-delà de 35° (hystérésis : sans elle, 12 bascules pivot/marche sur un trajet), arrivée à 25 cm,
  arrêt si le ToF ne voit pas 45 cm libres. Premier usage : **fatigué, il va faire la sieste dans son coin favori**
  (`coin_favori("nap")`, 0,5–4 m, ToF obligatoire, jamais sur batterie basse). Reste approximatif (odométrie qui dérive,
  remise à zéro au redémarrage de robotd) — UWB pour un vrai repère.
- **Garde-fou « chat agacé »** (section Le chat, non négociable, pas encore codé jusque-là) : 3 chutes en 10 min →
  veille assise 15 min au lieu de s'ébrouer et repartir.
- **Réflexes sonores** (`audio.py`, « hors de portée » levé pour la partie analyse) : pipeline micro sans deep learning
  — choc très fort → `bruit` (sursaut existant), 2–3 claquements réguliers → `appel` (« oui ? »), applaudissements →
  joie, battement régulier → **il danse de la tête au tempo** et s'arrête avec la musique (une fois par 5 min au plus).
  Claquement / syllabe distingués par le temps de montée (sous-blocs de 2,5 ms) : 140/140 sur 7 scénarios × 20 graines,
  dont de la parole simulée. Source `MicroAlsa` (arecord) **non testée** ; partage du micro avec quacksat à prévoir.
- **`canard.py`, lanceur du canard complet** : `pont_ha.py` lançait le cerveau **sans ToF ni caméra** — en production,
  promenade, main tendue, coin de sieste et jeu auraient été inactifs. `canard.py` assemble ce qui est disponible
  (robotd, tofd, caméra, `--chat`, `--micro`, HA + `[cerveau]`, mémoire). Déploiement Pi mis à jour (service sur
  `canard.py`, tunnel SSH qui transporte aussi `tofd` et la caméra en local, numpy/OpenCV ajoutés — chemin du socket
  `tofd` sur le robot **supposé** `/run/tofd.sock`).

**À faire sur le PC (duck-sim), dans l'ordre** : (1) `bash ~/run-brain.sh canard.py --sans-ha 300` dans l'appartement
(rien ne casse, promenade toujours sûre) ; (2) main tendue : la simulation n'a pas de main — vérifier au moins qu'aucune
fausse main n'est vue en `chill` près des meubles ; (3) 1-2-3 soleil en arène avec la balle téléportée comme « joueur »
qui bouge (vérité terrain) ; (4) coin de sieste : `eval_promenade.py` avec énergie basse. **À la livraison** : caresse
(amplitude), `pet-detect`, chemin de `tofd`, micro (périphérique ALSA, partage avec quacksat), mémoire sur Pi 3B+.

### 2026-10-05, nuit — validation `duck-sim` bloquée ; taquineries : socle + lot A

- **`duck-sim` dans le cloud : presque**. Le dépôt officiel `pollen-robotics/microduck` se clone, les daemons compilent
  (Rust ≥ 1.99 requis), `uv sync` de `microduck_rl` passe sur CPU — mais les **politiques ONNX** (marche, debout…) ne
  sont que sur Hugging Face, et `huggingface.co` est **refusé par la politique réseau** de l'environnement cloud (le
  connecteur HF ne lit que du texte). À ouvrir dans les réglages de l'environnement (Network access → Custom, ajouter
  `huggingface.co`) ; sinon la validation se fait sur le PC (ordre dans le journal précédent).
- **Découverte en lisant le code officiel** : le `pet-detect` de Pollen est **audio** (le micro est dans la tête, il
  entend le grattage ; petit CNN log-mel), exécuté **par `robotd`**, qui roucoule tout seul ; une « sentinelle » y classe
  déjà les sons en `Noise` (claquement, choc) / `Voice` (parole). **Rien de tout ça n'est exposé aux clients** (« pas de
  consommateur avant le cerveau autonome »), et **le micro n'accepte qu'un client** : notre `MicroAlsa` (audio.py) ne
  pourra pas tourner à côté. Conséquences : (1) la caresse par les servos de tête (`caresse.py`) reste utile tant que
  `pet-detect` n'est pas exposé ; (2) piste de **contribution amont** : publier petting / Noise / Voice dans
  `robot.subscribe` — exactement ce dont notre cerveau a besoin ; (3) nos réflexes sonores (`audio.py`) devront se
  brancher sur ce flux ou sur un partage ALSA.
- **Taquineries, socle commun** (`taquineries.py`) : budget de malice, signal stop, mémoire des blagues persistante
  (running gag, trophée de malice). **Lot A** : feinte de bec, esquive puis accepte la main, faux endormi / sourde
  oreille sur un appel, regard mystérieux, faux bâillement d'ennui, dernier mot dans les silences, « non » théâtral (sous
  budget), fausse feinte avant le tir (`approach.py`, option `feinte`, désactivée par défaut : la tête pèse 38 % de la
  masse, **à mesurer en arène** avec `approach_eval.py --feinte` avant de l'activer dans `jeu.py`).
- **Défaut trouvé** : une discussion dense passait parfois pour de la musique (le canard aurait dansé) → le tempo exige
  maintenant une corrélation au double de la période et 2 s de tempo stable. 110 tests, robustes sur 20 graines.

### 2026-10-05, fin de nuit — tout le code faisable sans robot, validation groupée plus tard

Décision : pas de `duck-sim` dans le cloud (Hugging Face bloqué) → **tout coder, tout valider d'un coup plus tard**.
`microduck-brain` : **142 tests unitaires** (dont 3 d'endurance) ; tout compile en Python 3.11.

- **Taquineries lots B, C, D (partie sûre)** : voir « Chantier suivant » ci-dessus. Nouveau `balle.py` (veille de la
  balle, 2 images/s ; `approach.py` lui délègue son estimation).
- **Maison** : alarme fumée / CO (`[[appareil]] type = "fumee"`) **prioritaire sur tout**, même le mode calme, la sieste,
  une conversation ou les bras ; météo (`type = "meteo"`, `weather.*`) : réagit au *début* de la pluie, à la neige,
  se blottit dans son coin par orage, moins envie de promenade quand il pleut ; tours sur demande (boutons HA :
  salut, toupie à l'odométrie, assis/debout) ; toilette après une impression.
- **Social** : salut propre à chaque habitant (choisi par son nom, stable), découragement progressif (demande d'attention
  ignorée → il demande deux fois moins souvent, puis s'occupe seul), geste signature une fois par jour, gêne après une
  chute devant quelqu'un, attente inquiète quand quelqu'un tarde (heure habituelle de `memoire.py`), refuge après une
  série de détonations (pétards, orage).
- **Navigation** : chargeur appris (la batterie remonte sans qu'il bouge) et retour au chargeur sur batterie basse ;
  coin d'observation en journée. HA : `binary_sensor.microduck_veille`, `sensor.microduck_blagues`.
- **Ce que `robot.state` sait déjà** (lu dans le code officiel) : `safety.picked_up` (détecteur officiel « pris dans
  les bras ») → état `porte` (M9 « Held ») ; `currents_ma` (v36, « la seule mesure de force extérieure ») → la caresse
  utilise aussi le courant des servos de tête ; `targets` (consignes réelles).
- **Contribution amont prête** : `microduck-brain/contrib/robotd-audio-state.patch` pour `pollen-robotics/microduck`
  — `robotd` publie `RobotState.audio = {petting, pettings, noises, voices}` (compteurs, jamais manqués par un abonné
  décimé). Compile, tests officiels `duck-ipc-proto` (+1), `robotd`, `robotctl` passent. Débloque la caresse audio
  officielle et les sons pour le cerveau (le micro est mono-client et `robotd` l'occupe). Le cerveau le lit déjà.
- **Défauts trouvés par les tests** : arrêté pendant une sieste du mode calme, le cerveau laissait le canard assis et le
  croyait debout au démarrage suivant (chaque `sit_toggle` aurait fait l'inverse) → `arret()` relève toujours, et le
  premier tick se cale sur `policy == "sit"` ; une demande d'attention était jugée « ignorée » 10 s après (60 s
  maintenant) ; une course dans un test HA.
- **Tests d'endurance** (`test_endurance.py`) : 3 × 2 h et 2 × 1 h simulées avec un flux aléatoire de tous les événements,
  chutes, prises dans les bras et capteurs factices ; invariants à chaque commande : jamais de marche sans capteur de
  distance, jamais un pas vers un vide, aucune commande de marche dans les bras, aucun son en mode calme hors alarme
  incendie, jamais laissé assis à l'arrêt.

**À valider d'un coup (PC + `duck-sim`, puis robot)** : tout ce qui est listé dans les journaux du 2026-10-05 ; en
priorité ce qui touche la sécurité (promenade, aspirateur, poussée de balle, fausse chute, navigation), puis les
réglages audio (seuils sur le vrai micro), la caresse (amplitude, courant) et `ground_pick`.

### 2026-10-06 — règles d'identité verrouillées, cerveau découpé, suite de la roadmap

**Deux règles décidées par l'utilisateur, désormais vérifiées par des tests (`test_regles.py`)** :
1. **Le canard ne s'exprime qu'avec ses sons de canard** (banque officielle `SoundTag` : `alarm`, `greet`, `inquire`,
   `peck`, `chirp`, `coo`, `wheee`) — tout autre son est refusé par `Ctx.sound`, aucune synthèse vocale.
2. **Tout tourne sur le canard, aucun appareil réseau n'analyse ses données** : `deploy/pi/` supprimé (plus de repli
   sur un Pi), `canard.py` refuse une caméra lue à distance, seul le pont Home Assistant parle au réseau et n'envoie que
   des états. Liste exacte des modules embarqués : `deploy/robot/modules.py`.

**Conséquence : quacksat est écarté** (il envoie le son du micro hors du canard et répond par synthèse vocale). Remplacé
par des **commandes vocales locales** (`commandes.py`) : Vosk hors ligne (modèle français ~40 Mo téléchargé une fois),
grammaire restreinte, nom du canard obligatoire (« <nom> assis / debout / viens / tourne / on joue / stop / chut /
réveille-toi / bravo / danse »), réponses en sons de canard, hésitation (« inquire ») s'il n'a pas compris.
**Micro partagé** : il est mono-client et `robotd` le tient → second patch amont `contrib/robotd-audio-capture.patch`
(`[audio] capture` séparé du haut-parleur ; tests officiels OK) + `deploy/robot/asound.conf` (`dsnoop`). À noter : la
caresse officielle (audio) est **désactivée par défaut** dans `robotd` (`[audio] pet_detect = true` à mettre).

- **`brain.py` découpé** (2 300 lignes) : `etats_base.py`, `etats_vie.py`, `etats_jeux.py`, `etats_taquineries.py`,
  `etats_maison.py` ; `brain.py` garde `Brain`/`run` et réexporte tout (aucun import existant ne change).
- **Auto-préservation thermique** (`robot.health`) : servo ≥ 60 °C → repos assis sans se relever entre deux siestes, il
  halète bec entrouvert ; reprise sous 50 °C ; carte ≥ 85 °C → veille caméra en pause. HA : température des servos.
- **Entendus sur le canard, sans Home Assistant** : l'**alarme incendie** (bips aigus réguliers, motif T3) → alarme
  prioritaire ; **on frappe à la porte** (chocs graves, distincts des claquements de mains aigus) → réaction sonnette.
- **Remarque un objet qui n'était pas là avant** (mémoire des cases traversées, 7 jours) : arrêt, regard, « inquire ».
- **Habitudes sonores** (`habitudes.py`) : silence inhabituel à une heure d'habitude animée → petit tour pour aller voir ;
  rythme semaine / week-end (`bonjour_weekend`).
- `microduck-brain` : **164 tests** (dont endurance et règles).

### 2026-10-06, suite — personnalité, jeu de balle autonome, M9 complet

- **Personnalité qui évolue** (`personnalite.py`) : curiosité, sociabilité, espièglerie, prudence. Tempérament de base
  tiré une fois (chaque canard est unique), sauvegardé sur le canard ; façonné par sa vie (caresses, accueils, objets
  nouveaux, taquineries, « stop », chutes, demandes ignorées), retour lent vers la base (moitié en 3 jours). Module
  l'envie de se promener, de taquiner, la patience avant de chercher de la compagnie. HA : trait dominant.
- **Jeu de balle autonome dans le cerveau** (M9 *BallPlay*, projet prioritaire n°1) : `approach.py` est devenu pilotable
  trame par trame (`etape`), sans changer `run()` ; état `balle` : approche + tir avec vision, fête si la balle part,
  **dépit comique puis regain de motivation** si elle reste là (3 essais max). Sécurité ajoutée : un vide devant annule
  la commande du contrôleur. Lancé par la voix (« la balle »), un bouton HA, ou de lui-même quand il voit sa balle.
- **Cache-cache lancé par le canard** (avec indices sonores « peck » ; trouvé par la voix, une caresse, une main ou de
  près ; il sort seul après 5 min).
- **M9 complet** : *Zoomies* (petite folle course, 80 cm libres exigés, jamais avec le chat) et *GroundPick* spontané.
  Les 16 états de la machine M9 de Pollen ont leur équivalent.
- `microduck-brain` : **179 tests**.

### 2026-10-06, soir — banc de validation groupée, revue de code

- **`valider_sim.py`** (banc de la validation groupée, à lancer en premier sur le PC contre `duck-sim`) : scénarios
  `promenade`, `main_fantome`, `coin_sieste`, `jeu_balle`, `soleil`, `aspirateur`, `cascades`, `pousse_balle`. Il utilise
  la vérité terrain du fork (`truth.py`) pour MESURER seulement, et donne un verdict par scénario.
- **Revue de code** du cerveau : **10 défauts réels corrigés**, dont plusieurs touchaient à la sécurité.
  - Vide vérifié à chaque trame pendant « pousse la balle ».
  - Tête baissée pendant les Zoomies, pour que le ToF voie le sol.
  - Assis/debout resynchronisé après une chute (en mode calme, il retourne s'asseoir).
  - Verdict du tir fondé sur une image prise après le tir.
  - `fin_jeu` arrête le jeu de balle et le cache-cache.
  - Sons « une fois » indépendants de la cadence des trames.
  - Verrou sur les prises HA.
  - Le joker HA ignore le retour d'`unavailable`.
  - Caméra distante refusée.
  - Le micro ne s'entend plus lui-même (`VoixPropre`).
  - `test_revue.py` verrouille chaque correction.
- **Rythme visible** : sur de la musique, avec une caméra, le canard regarde d'abord 4 s sans bouger. Si quelqu'un
  bouge en rythme devant lui, il danse avec cette personne : un « wheee » et des hochements plus amples. Sinon, il
  danse seul.
  - Méthode : `mouvement.rythme_correspond`, autocorrélation de la différence d'images à un battement.
  - À valider sur le robot : le seuil de 0,4 et la cadence de 10 images/s.
- `microduck-brain` : **197 tests**. Ce qui reste dans la roadmap demande le robot ou une nouvelle infrastructure :
  - détection de personne sur le NPU (lot C) ;
  - UWB pour savoir où sont les habitants ;
  - micro stéréo pour le cache-cache au son ;
  - ce que fait vraiment `ground_pick`.

### 2026-10-06, nuit — diagnostic, pistes « vivant », capteurs maison par la caméra

Tout est codé et testé sans robot (232 tests dans `microduck-brain`). Rien n'a été essayé contre `duck-sim` ni sur le
robot.

- **Diagnostic / auto-surveillance** (`diagnostic.py`, section « à faire plus tard » ci-dessus) :
  - batterie dans la durée : cycles de décharge, autonomie estimée, santé de la batterie, avis « à remplacer » ;
  - santé des servos : courant et écart consigne-position au repos, comparés aux 3 premiers jours, et le servo le
    plus souvent le plus chaud ;
  - journal des chutes : activité risquée et endroit qui revient ;
  - **auto-test au premier réveil du jour** (sans bouger les jambes) : robotd, boucle, bus, IMU, ToF, caméra, et la
    tête qui suit ses consignes.
  - Tout est publié dans HA. `robot.health` ne donne que le servo le plus chaud, pas la température de chacun.
- **Pistes « vivant »** :
  - rythme circadien (opt-in, activé par `canard.py`) ;
  - petits sons gratuits ;
  - discrétion au téléphone (`audio.py` : une seule voix coupée de blancs) ;
  - timidité avec un visiteur inconnu (sonnette puis voix sans habitant qui rentre) ;
  - jour spécial du calendrier HA (type `calendrier`) ;
  - bâillement contagieux (`audio.py`) ;
  - coup d'œil vers un mouvement en périphérie ;
  - heure des repas (`[cerveau] repas`, lieu appris là où l'on parle à ces heures) ;
  - tenir compagnie (déclencheur HA `compagnie`, lieu appris là où on le caresse).
- **Capteurs maison par la caméra** : lumière oubliée (la nuit, maison vide, image lumineuse) et objets nouveaux au
  sol, publiés dans HA.
- **À étalonner sur le robot** : seuils audio (téléphone, bâillement), seuil de luminosité 0,25, et le critère de
  dérive des servos.
- **Relecture du code de la nuit : 13 défauts réels corrigés**, chacun avec son test dans `test_revue.py`. Le plus
  important : `robot.state.joints` compte **15** articulations, avec le **bec à l'index 9** (`duck-ipc-proto`
  `JOINT_NAMES`). Toute la jambe droite était décalée d'un cran dans le suivi des servos.
  - Autres corrections : sieste possible pendant un appel, l'alarme incendie jamais rendue muette, présence initiale
    lue dans HA au démarrage, cycle de batterie conservé au redémarrage, résumé HA calculé hors de la boucle à 50 Hz.
- **Ambiance et maison** :
  - il se retire dans son coin quand l'ambiance est très bruyante ;
  - les bips d'un appareil (four, micro-ondes) le rendent curieux ;
  - avec l'aspirateur, il est méfiant les premières fois, curieux ensuite, puis l'ignore.
- **Nuances sociales** :
  - **ton de son nom** : `commandes.py` mesure le niveau et la hauteur du mot, aux instants donnés par Vosk. S'il est
    grondé, il est penaud, tête basse, sans un son, et ne fait plus de blague un moment. S'il est cajolé, il
    roucoule.
  - **visiteur récurrent** (`visiteur:<nom>` depuis HA) : moins timide à chaque visite ;
  - **batterie entre 25 et 40 %** : il va d'abord voir quelqu'un avant d'aller au chargeur.
- **Coût du cerveau mesuré** (`bench_cerveau.py`, à relancer SUR le canard à la livraison) : 0,027 ms par trame en
  moyenne sur PC, 0,09 ms pour 99 % des trames, environ 2 ms au pire, pour un budget de 20 ms.
  - La sauvegarde de la mémoire est maintenant compacte, environ 1 ms au lieu de 4 ms pour plusieurs mois de mémoire.
  - Elle est écrite sur le disque dans un fil séparé, sans faire attendre la boucle.
- **Banc `valider_sim.py` : 13 scénarios**. Les 5 nouveaux :
  - `autotest` : contre le vrai robotd ;
  - `bec_index` : vérifie que le bec est bien l'index 9 des articulations ;
  - `compagnie` ;
  - `coup_oeil` ;
  - `gestes_nouveaux`.
- **Personnalité saisonnière** : l'été, plus vif le matin et ramolli l'après-midi ; l'hiver, siestes plus longues.
  Elle suit la température extérieure de HA (appareil de type `temperature`), ou le mois à défaut.
- **Voix personnelle qui évolue** : les petits sons qui font réagir la maison reviennent plus souvent, et tous
  dérivent un peu chaque jour.
- **Pétards et feux d'artifice**, distincts du tonnerre : il va s'abriter 10 min.
- **Deux relectures** (la tienne et une automatique) : tout est corrigé, avec des tests.
  - Champs `null` de robotd (`battery`, `safety`, `odom`, `frames`) : ils plantaient le tick ou le ToF.
  - Ton du nom : il écrasait la commande qui le suivait.
  - Le niveau de référence du ton restait figé.
  - Des applaudissements forts étaient pris pour des pétards.
  - Un visiteur sans prénom était mémorisé comme un « être ».
  - Deux déclencheurs HA sur la même entité s'écrasaient.
  - Mémoire : arrêt propre sur SIGTERM, avec une dernière sauvegarde.
  - Scénario `coup_oeil` du banc : impossible à réussir tel quel, corrigé.
- `ha.exemple.toml` est à jour : toutes les options du cerveau y figurent.
- **`scripts-wsl/valider-tout.sh`** fait toute la validation groupée en une commande : tests, coût du cerveau, puis
  les 13 scénarios dans `duck-sim`, scène par scène. Il écrit un rapport daté.
- **Le canard déclenche des scènes dans la maison** (projet prioritaire n°2, partie qui manquait) : sections
  `[[action]]` de `ha.toml`.
  - Déclencheur : un état du canard (accueil, bonjour, sieste…) ou un événement, qui appelle un service HA.
  - Ou une phrase vocale (« canard, lumière du salon »), reconnue sur le canard ; seule la commande part vers HA.
  - Une action dont l'entité n'est pas remplie est ignorée : `light.turn_on` sans cible allumerait toutes les
    lumières.
- **Mode garde** (opt-in) : maison vide et voix, choc ou coups à la porte → événement HA `microduck_garde`, avec
  seulement le type de son.
- **Journal de bord du jour** dans HA (`sensor.microduck_journal`).
- Le journal des états du cerveau est maintenant borné : il grossissait d'environ 1 Mo par jour.
- `microduck-brain` : **277 tests**.

### 2026-10-06, fin de soirée — application Microduck, diagnostic à la main, deux relectures

- **Application Microduck** (téléphone, servie par le canard, sans HA) : v1 faite, voir la section « Application
  Microduck » plus haut.
- **Diagnostic lancé à la main** (appli ou bouton HA) : il se joue au prochain moment de repos, batterie comprise
  (niveau, tension, santé, autonomie).
- **Deux relectures corrigées** :
  - actions HA : une action sans cible est refusée ; une plage horaire mal écrite ne fait plus planter le canard ; pas
    de double appel ; le « oui » n'arrive que si l'action est vraiment partie ;
  - mode garde : il ne s'entend plus lui-même, et une présence inconnue ne compte plus comme maison vide ;
  - journal du jour : remis à zéro à minuit, et gardé en mémoire ;
  - batterie : le rebond de tension est filtré ;
  - auto-test : fonctionne aussi à 10 Hz.
- `microduck-brain` : **295 tests**.

### 2026-10-06, nuit (suite) — une application complète, avec ou sans Home Assistant (APK 1.0)

- **Lot 1, sans Home Assistant** : installation depuis le téléphone au premier démarrage (30 min, réseau local, une
  seule fois) ; `configuration.json` remplace `ha.toml` section par section (secrets jamais relus par l'appli, fichier
  600) ; HA devient facultatif ; profil **enfant** (jouer, regarder, le retrouver ; ni réglages ni sauvegarde) ;
  imprimantes suivies **en direct** sur le réseau local : Prusa (PrusaLink) et Elegoo Saturn (SDCP par WebSocket).
- **Lot 2, vivre avec lui** : studio de chorégraphies (tête, sons de canard, gestes, pauses ; programmables en
  routine), comportements de `robotd` à essayer et installer, curseurs de caractère (joueur / bavard / taquin),
  statistiques du jeu de balle, télécommande au doigt et regard au pavé tactile.
- **Lot 3, entretien** : mise à jour du cerveau depuis l'appli (`deploy/robot/mettre_a_jour.sh`, retour arrière
  possible), rapport de diagnostic sans donnée personnelle, plusieurs canards dans l'APK, aide intégrée.
- **Lot 4, partage** : appli et APK en anglais (langue du téléphone), publication de l'APK par GitHub Actions
  (étiquettes `apk-v*`, clé de signature en secret GitHub, jamais dans le dépôt). Catalogue : guide de contribution,
  formulaire « proposer une pièce », modèle de PR (`microduck-catalogue`).
- `microduck-brain` : **334 tests**. APK 1.0 : `android/microduck.apk` de la branche.
- **À valider sur le robot** : noms des requêtes `robotd` des politiques (`robot.policies`, `policy.search`,
  `policy.install`), codes d'état SDCP de la Saturn 4 Ultra, clé PrusaLink de la MK4S.
- **Après fusion dans `main`** : passer l'adresse de mise à jour (`Accueil.DEPOT`, `BRANCHE` de `connexions.js`) sur
  `main`.

### 2026-10-06, fin de nuit — application 1.1 (lots 5 à 8) et clé de signature à toi

- **Clé de l'APK** : `android/creer_cle.sh` (une commande dans WSL) crée TA clé, la sauvegarde dans Documents et la
  donne à GitHub (secrets). Ensuite, GitHub publie l'APK tout seul à chaque version (`apk.yml`, release
  `apk-v<version>`). Guide : `android/CLE_DE_SIGNATURE.md`. Il faudra désinstaller une fois la 1.0/1.1.
- **Lot 5, au quotidien** :
  - messages laissés au canard, signalés en sons de canard au retour de la personne ;
  - mode vacances (calme + garde, nouvelles chaque soir à 20 h) ;
  - « où l'a-t-il vu ? » (chat, balle par la caméra, objet) ;
  - journal photo **opt-in**, gardé sur le canard 7 jours ;
  - corrigé : l'arrivée par le téléphone ne déclenchait pas l'accueil.
- **Lot 6, jeux** : balle guidée et parcours chronométré (points posés sur sa carte, records), mode photo avec pose.
- **Lot 7, santé** : courbes d'usure des servos, comparaison des batteries, carnet d'entretien. Un servo ou une batterie
  remplacés repartent d'une mesure neuve.
- **Lot 8, ouverture** :
  - codes invités temporaires, avec QR code ;
  - partage des chorégraphies (fichier, texte, QR, rubrique du catalogue) ;
  - G-code du catalogue envoyé à la Prusa par PrusaLink : le téléphone télécharge, le canard dépose ;
  - photo de fin d'impression.
- `microduck-brain` : **357 tests**. Catalogue : `[[fichier]]` (G-code par imprimante) et `choregraphies/*.json`.
- **À valider sur le robot / le matériel** :
  - nom du stockage PrusaLink (`usb`) et l'en-tête `Print-After-Upload` sur la MK4S ;
  - la caméra pour les photos (`/frame` de mediad) ;
  - les parcours dans `duck-sim` (dérive de l'odométrie).

### 2026-10-07 — le canard plus vivant (`vivant.py`, APK 1.5), session cloud

Dix comportements purement côté robot, codés et testés (379 tests), **aucun validé dans `duck-sim`** :
1. **Respiration et micro-saccades** au repos (cou ± 0,015 rad sur 4 s, coups d'œil ± 0,035 rad). Un repos sur trois
   environ est « aux aguets » (tête figée) : c'est là qu'il guette les mouvements. Le détecteur de caresse suit
   désormais la consigne qui bouge lentement (respiration) au lieu d'une consigne fixe.
2. **Habituation** : un même bruit isolé, un bip, un mouvement en périphérie qui revient le font réagir de moins en
   moins ; oublié au bout de quelques heures (demi-vie 30 min). Les vacarmes (série de bruits) ne s'habituent pas
   (sécurité : pétards, alarme).
3. **Tour de parole sonore** : après un appel, une caresse, la main tendue, des applaudissements, il « répond » 45 s
   aux phrases qu'on lui dit (fin montante → `inquire`, descendante → `coo`, courte → `chirp`). Jamais à la télé ni à
   une conversation qui ne lui est pas adressée. `audio.py` émet `enonce:<durée>|<sens>` (voix voisée seulement).
4. **Bouderie** après une remontrance ou des appels ignorés (tête détournée 1-2,5 min, regard en coin à l'appel) ;
   **réconciliation** par une caresse ou la main tendue.
5. **Jalousie du chat** : chat caressé devant lui (boîtes chat/personne collées sur 3 images) → il vient réclamer.
6. **Attente à la porte** : heure de retour apprise par habitant (médiane, semaine/week-end, ≥ 4 retours réguliers) ;
   il va à l'entrée (apprise à l'accueil) 15 min, une fois par jour.
7. **Souvenirs de lieux** : bons moments (caresse, jeu) et mauvais (bruit, chute) notés à leur position ; parfois il
   retourne au bon coin (nostalgie), il hésite en passant au mauvais.
8. **Âge** : jeunesse les 21 premiers jours (plus timide avec les inconnus, un peu moins patient seul), assurance des
   taquineries qui passe de 0,5 à 1 en 60 jours. **La maladresse ne change pas** (elle fait partie du personnage).
   Âge affiché dans l'appli (Personnalité).
9. **Suis-moi** (ToF : la jambe la plus proche devant, 0,2-1,6 m ; pivote, avance au-dessus de la zone morte,
   abandonne après 3 s perdu) et **je te suis** (il mène quelques pas, se retourne, `wheee` si on le suit). Commandes
   vocales, boutons de l'appli et de HA.
10. **Balle soulevée** (> 15 cm) → excitation (dandinement, `wheee`), pas en boucle.

Le 11 (gestes du corps : trépigner, saut de joie, s'ébrouer, se gratter, s'allonger) demande le GPU : file d'attente
RL en Phase 1.

À valider en premier sur le PC : la respiration ne déclenche pas de fausse caresse sur le vrai `robotd`, le
suis-moi avec le ToF de `duck-sim`, les seuils de l'énoncé avec le vrai micro (à la livraison).

### 2026-10-07, suite — son personnage (`personnage.py`, APK 1.6), session cloud

Douze comportements de plus, codés et testés (396 tests), **aucun validé dans `duck-sim`** :
1. **Hoquet** : « hic » (peck + tête qui sursaute) toutes les 2-3,5 s pendant 20-45 s ; rare (plus probable après
   un repas, une fois par 3 h au plus). Une caresse ou une surprise le fait passer (`gueri`).
2. **Gaffe** : un obstacle vu à moins de 30 cm en promenade (surgi au dernier moment) → sursaut, « non », regard vexé
   vers l'objet, puis un grand pivot exagéré. Rare (1 sur 3, 10 min d'écart) ; pivots sur place seulement.
3. **Fierté / déception** (jeu de balle) : tour de victoire sur place (toujours sur un nouveau record de série, une
   fois sur deux sinon), tête basse 4 s après l'abandon, perplexe (« inquire », regard à gauche et à droite) si la
   balle n'est plus trouvée.
4. **Nid** : avant une sieste de fatigue, deux tours sur lui-même puis un « coo » (une fois par heure au plus ; jamais
   sur batterie basse ni sans capteur de distance).
5. **Cabotinage** : un « numéro » (taquinerie, gag, geste rare, danse...) joué devant quelqu'un, suivi d'un rire ou
   d'applaudissements dans les 20 s → il prend un air fier et le refera plus souvent ; sans réaction → un peu moins
   (scores gardés dans la mémoire).
6. **Rituels par habitant** : une caresse quand une seule personne est là est notée à l'heure ; 4 jours sur 14 à la
   même heure → il vient la réclamer (une fois par jour).
7. **Objet nouveau** : après la remarque existante, une fois sur deux il s'approche à 20 cm et le picore ; habituation
   quand les nouveautés s'accumulent.
8. **Doudou** : sa balle après 3 parties ; parfois il va la retrouver (arrêt à 25 cm), la picore (`ground_pick`, mime
   tant que le skill n'est pas mesuré) et reste posé à côté.
9. **Rythme** : `audio.py` émet `motif:<écarts ms>` pour 2 à 8 tapes ; pendant une conversation (après un appel...)
   il le rejoue en coups de bec, parfois avec un coup de trop et un air fier.
10. **Nom sonore** : 2-3 sons de canard propres à chaque habitant ; dit après un appel (une seule personne familière)
    et quand il réclame son rituel.
11. **Ambiance** : `audio.py` émet `rire` (éclats réguliers et détachés) et `ambiance:tendue` (4 énoncés très forts en
    20 s) → il rit avec vous / se fait tout petit et muet, sans blague pendant 10 min. Seuils à étalonner.
12. **Bain de soleil** : de 9 h à 19 h, toutes les 10 min au repos, une image : une tache très lumineuse dans la moitié
    basse (le sol) → il pivote vers elle, avance 2,5 s au plus, s'étire, s'assoit tête levée (40-90 s). L'étirement
    du corps entier attend le GPU (file Phase 1).

À valider en premier dans `duck-sim` : la gaffe (seuil de 30 cm avec le vrai ToF), le nid (deux tours sans dériver),
le tour de victoire, le bain de soleil (la scène appartement a-t-elle des taches lumineuses ?). Audio (rires, voix
tendues, rythme) : à étalonner avec le vrai micro à la livraison.

### Prochaines étapes — ce qui rend le canard vivant, priorité à l'interaction humaine

Vue d'ensemble du **Chantier actif** (section plus haut) et de la table « Interactions par habitant » (Humains)
pour la prochaine session comportementale (toujours sans RL/GPU) : ce qui est fait, ce qui reste, dans l'ordre
où ça apporte le plus de « vivant » par rapport à l'effort.

**Déjà fait (cette session et avant)** : accueil au retour avec familiarité, rituel de départ, occupation
autonome / recherche d'attention après ennui, notifications maison (impression 3D), heures calmes nocturnes
(opt-in), suivi du chat avec recul si approche rapide, publication HA (état, énergie, éveil, batterie, position,
habitants présents, chat vu).

**Prochaines pistes humaines, par ordre d'impact probable** (état au 2026-10-05 soir) :

1. ~~Caresse~~ — **fait** (détecteur maison sur les servos de tête + événement ouvert à `pet-detect`) ; à valider.
2. ~~Main tendue~~ — **fait** (ToF) ; à valider (portée et réflectivité de la peau sur le VL53L5CX).
3. **Messager physique** — **fait côté maison** (sonnette, machines, prise à puissance, message redit au retour).
   Reste « vient te voir là où tu es » : la navigation vers un point existe maintenant (`navigation.py`), il manque
   **où est l'habitant** (UWB, ou au moins la pièce via quacknav).
4. ~~Jeux sociaux légers~~ — **1-2-3 soleil fait**. Cache-cache au son : demande la direction du son (le micro du
   canard est-il stéréo ? à voir à la livraison) ; sinon cache-cache visuel quand la détection de personne tournera
   sur le NPU.
5. ~~Commandes vocales (quacksat)~~ — **quacksat écarté** (2026-10-06) ; commandes vocales **locales** faites
   (`commandes.py`), à valider avec le vrai micro partagé.
6. ~~Routine du matin~~ — **fait** (`bonjour`).

**Nouvelles pistes ouvertes par cette session** (**toutes faites au 2026-10-06** : rythme visible dans `Danse`, silence
inhabituel `habitudes.py`, `va_observer`, chargeur appris, `binary_sensor.microduck_veille` + `sensor.microduck_etat`) : rythme visible (« quelqu'un qui bouge en rythme devant lui ») en
combinant `mouvement.py` et le tempo d'`audio.py` ; « silence inhabituel » (habitudes apprises × niveau sonore) ; coin
« d'observation » (`coin_favori("chill")`) visité en journée ; apprendre la position du chargeur (là où la batterie
remonte) pour y aller sur batterie basse ; publier `veille`/`jeu en cours` dans HA.

### Chantier suivant (décidé le 2026-10-05) : « taquiner l'humain »

Après la validation dans `duck-sim` des ajouts du 2026-10-05 : **tout ce qui est taquinerie** (section « Taquineries
envers les humains » ci-dessus, 35 idées) — déplacer / planquer les objets au sol, imiter l'humain pour s'en moquer, faux
endormi, photobombe, etc. Triées ci-dessous selon les briques existantes ; on les code dans cet ordre.

**État (2026-10-05, nuit) : socle commun, lot A, lot B, lot C (sauf ce qui demande de voir une personne marcher) et la
partie sûre du lot D FAITS** (`taquineries.py`, `balle.py`, `audio.py`, états de `brain.py` ; tests dans
`test_taquineries.py`) ; rien d'essayé contre `duck-sim` (validation groupée plus tard, décision du 2026-10-05).

**Socle commun, à coder en premier** (sans lui, une taquinerie devient une nuisance) — **fait** (4 par heure, 5 min
d'écart, familiarité ≥ 0,6, stop = bouton HA `button.microduck_stop_taquinerie` ou événement `non`, bloque 30 min ;
running gag après 5 fois la même blague) :
- un **budget de malice** : quelques taquineries par heure au plus, jamais la même deux fois de suite, seulement si
  la familiarité de la personne est élevée (`memoire.py`), jamais en mode calme, la nuit, pendant une conversation
  vocale ou juste après un accueil ;
- un **signal « stop »** qui coupe net toute taquinerie en cours et en bloque de nouvelles pendant un moment :
  « non » vocal (quacksat), main qui l'écarte (ToF), `fin_jeu`, bouton HA ;
- la **mémoire des blagues** (compteurs par taquinerie et par personne) : sert au « running gag » et au « trophée de
  malice » (petit air fier qui grandit avec l'historique).

**Lot A — faisable avec ce qui existe déjà (code pur, testable contre `duck-sim`)** — **fait** sauf validation :
- ~~« Non » théâtral avant d'obéir~~ — **fait** (état `taquin`, 1 fois sur 5 avant 1-2-3 soleil) ;
- feinte affectueuse (coup de bec dévié + petit bond en arrière) — sur la main tendue (`main_tendue.py`) ;
- se faire désirer avant la caresse (esquive la main qui approche une fois, accepte la suivante) — ToF ;
- faux endormi quand on l'appelle / fait mine de ne pas entendre, puis réaction exagérée — sur l'`appel` (audio) ;
- regard mystérieux vers un point vide — `robot.look` scripté, sans aucune alerte derrière ;
- bâillement « sarcastique » / faux bâillement d'ennui pendant une longue discussion — geste + son, discussion
  repérée par le niveau sonore continu (`audio.py`) ;
- « toujours le dernier mot » — petit son dans les silences d'une conversation (parole puis silence, `audio.py`) ;
- fausse feinte avant un tir — tête vers une direction, tir dans l'autre (`approach.py`, Phase 2) ;
- trophée de malice et running gag — mémoire des blagues ci-dessus.

**Lot B — déplacer / jouer avec les objets au sol** (le cœur de « déplacer les objets ») — **fait** : pousser la balle
hors de portée, **mime** de vol (`ground_pick` = s'accroupir et piquer le sol, piloté par le robot ; on ne sait pas s'il
saisit : à requalifier sur le robot), aspirateur (curiosité, barre le chemin, s'écarte toujours avant 30 cm) :
- pousser un objet léger juste hors de portée — la balle orange existe déjà (vision HSV + approche + tir doux
  `BallKickPasse` en entraînement) : la pousser quand une main s'en approche (ToF), une ou deux fois seulement ;
- vol et planque ludique d'un petit objet — skill officiel `ground_pick` (déjà accepté par `robot.do`) ; à étudier :
  ce que fait vraiment le skill (prendre ? tenir ? lâcher ?), et reconnaître un objet « sans importance » (couleur
  ou tag NFC, pas de deep learning sur le Pi) ; s'échapper si on approche = recul + rotation (zone morte : pas de
  fuite fine) ;
- taquiner le robot aspirateur — son état est dans HA (`vacuum.*` : `cleaning`), le ToF le voit comme un obstacle
  mobile : lui barrer brièvement le chemin, sans jamais le suivre.

**Lot C — imiter l'humain pour se moquer** (perception à construire) — **fait** : mimer l'intonation, compter les
éternuements. **Volontairement pas fait** : imiter le « non » de l'humain (« non » est le signal stop des taquineries).
Restent ceux qui demandent de voir une personne marcher (NPU) :
- mimer le ton de voix de qui l'appelle — extraire la courbe de hauteur (montante / descendante) au micro, la
  rejouer en sons de canard (`inquire` monte, à voir quels sons `robot.sound` permet) ;
- imiter en exagérant un geste qu'on vient de faire (« non » de la tête après qu'on lui a dit non) — le « non »
  vocal via quacksat ; le geste vu à la caméra demande une détection de personne (NPU) ;
- compter les éternuements — détecteur audio d'éternuement à construire (motif bref et fort, à étalonner) ;
- suivre les pas en miroir (copycat), se mettre en travers du chemin, détour dans les jambes, petite course, prendre
  la place / le siège « juste trop tard » — demandent de **voir une personne marcher et où elle va** : détection de
  personne sur le NPU du robot (à profiler à la livraison) ; garde-fous forts (jamais près d'un escalier, mains
  chargées, ni d'une personne âgée ou d'un enfant qui court).

**Lot D — plus tard (perception lourde ou risque)** — **partie sûre faite** : fausse chute comique (dandinement à
0,25 rad + assis, aucune vraie perte d'équilibre), parodie de notification (deux chirps). Le reste : photobombe / selfie / appel vidéo (détecter un téléphone pointé
ailleurs), s'installer sur l'objet cherché / le tapis de yoga / l'outil de l'atelier, « superviser » un rangement, air
mystérieux quand quelqu'un cherche (reconnaissance d'activité) ; parodie sonore de notification (dépend des sons
qu'accepte `robot.sound`) ; fausse chute comique (à faire avec `robot.pose` + `sit_toggle` sans vraie perte
d'équilibre, ou en RL — jamais au risque d'une vraie chute) ; ricanement si quelqu'un glisse (garde-fou fort :
inquiétude au moindre doute, à ne faire qu'avec une détection fiable).

**Toujours hors de portée sans nouvelle infrastructure** : détection de ton de voix (boude après réprimande), rire
(trop proche de la parole sans modèle), position des habitants (UWB) pour un vrai messager et l'accueil à l'entrée.
