# Progression — Projet Microduck

> Vue d'ensemble rapide. Détails complets : `ROADMAP.md`. Contexte technique : `CLAUDE.md`.
> Dernière mise à jour : 2026-10-07 (canard plus vivant).

## Fait

- **Environnement de dev opérationnel** : Windows/WSL2/CUDA, synchronisé via GitHub avec
  un laptop Linux (soumission de jobs sur GPU Hugging Face) et avec le robot lui-même à terme.
- **Pipeline d'entraînement RL maîtrisé** : entraîner, visualiser, exporter en ONNX, publier —
  le cycle complet a été fait et validé.
- **`duck-sim` opérationnel, caméra comprise** : les vrais logiciels qui tourneront sur le
  robot (contrôle, capteurs, caméra, mise à jour) tournent dès maintenant contre un canard
  simulé, en temps réel. Pas besoin d'attendre la livraison pour développer dessus.
- **Le « cerveau » commence** (repo `microduck-brain`) : pilote le canard simulé à distance via
  son API réseau, indépendamment du code d'entraînement.
- **Gestes expressifs sans entraînement** : non, oui, curieux, surpris, fatigué.
- **Vision et jeu de balle (Phase 2)** :
  - détection de la balle par la caméra, position 3D à 0,5–2 cm près de 11 cm à 1 m ;
  - suivi du regard ;
  - **contrôleur d'approche complet** : le canard voit une balle posée au hasard à 0,5–1 m,
    s'en approche, se place et la tire — **10 essais sur 10 réussis** sur une 1re série en
    simulation (arène vide, vérité terrain), ~25 s par essai (2e série à relevements plus
    larges : voir `ROADMAP.md`).
- **Pont Home Assistant écrit** (réactions du canard aux fins/échecs d'impression + publication de son état) ; validé
  contre un faux Home Assistant et contre le simulateur, **pas encore contre ta vraie installation**.
  Visée du tir (direction voulue) : 11 essais sur 12 dans les ±35°.
- **2026-10-04** :
  - jeu de balle **dans l'appartement : 15 tirs réussis sur 20** (puis cuisine 9/10 après réglage du pied droit) (8/20 le matin) — un défaut du simulateur rendait la
    balle invisible à moins de 14 cm de la caméra ; le dernier pas poussait la balle (remplacé par des micro-pas) ;
    en arène : toujours 9–10/10 ;
  - le canard **suit ton chat des yeux** et se souvient de lui : son accueil passe de méfiant à chaleureux au fil des rencontres ;
  - **promenade autonome sans se cogner** (capteur de distance de la tête) et mémoire des zones déjà explorées ;
  - petits gestes spontanés et rares (s'étirer, s'ébouriffer, se lisser les plumes, éternuer) ;
  - **interrupteur « calme »** pilotable depuis Home Assistant : le canard s'assoit et se tait.
- **2026-10-04, après-midi et soir** :
  - **se relever** : déjà assuré par le logiciel officiel du robot ; notre entraînement (évalué : ~100 %) arrêté, GPU libéré ;
  - **tir tolérant** (balle jusqu'à 15 cm devant) : pied droit entraîné, 26/36 contre 14/36 pour l'officiel au banc, mais pas
    encore de gain en partie complète dans l'appartement (7/10 et 8/10 contre 9/10) → tir officiel gardé par défaut ;
  - **jeu avec le chat** (affiche en simulation) : il cherche le chat, va à la balle et la lui passe — 3 passes sur 8, 3 sur 4
    quand il trouve le chat ; garde-fous (jamais de poursuite, pas de passe vers un chat trop près) ;
  - **Home Assistant branché sur ta vraie maison** (Saturn 4 Ultra et ta présence) ; accueil à ton retour (plus joyeux après
    une longue absence) ; publication MQTT prête (attend Mosquitto) ; le canard se tait pendant une conversation vocale ;
  - **sécurité** : il voit les marches (le robot n'a aucune protection contre les chutes) et s'arrête 40–50 cm avant ;
  - **trémoussement de joie** sans entraînement (inclinaison du corps) ;
  - étude de deux projets communautaires (voix pour Home Assistant, navigation/carte de la maison) : on s'appuiera dessus.
- **Simulateur officiel en ligne découvert** (essai des compétences du fabricant depuis un
  navigateur).
- **2026-10-05, session cloud (sans PC/GPU, comportemental pur dans `microduck-brain`)** : le canard ne reste
  plus simplement passif si on ne s'occupe pas de lui depuis longtemps — il joue seul, ou va chercher l'attention
  de l'habitant présent ou du chat ; mémorise l'endroit précis où il est tombé pour l'éviter ; a de petits « rêves »
  (tête + murmure) pendant la sieste profonde ; marque un petit signe discret quand quelqu'un part (symétrique de
  l'accueil au retour) ; se fatigue visiblement à basse énergie (tête, jamais les jambes) ; apprend un coin favori
  distinct pour se poser ou se reposer ; marque une pause avant un couloir étroit ; s'ébroue après une vraie
  immobilité prolongée plutôt que sur une simple minuterie ; se met au repos de sa propre initiative si sa vraie
  batterie descend sous 25 % ; recule d'un petit pas si le chat se rapproche trop vite ; publie « chat vu au
  salon » comme entité Home Assistant ; « heures calmes » nocturnes optionnelles (réutilise l'interrupteur calme,
  rien ne change si on ne les configure pas) ; publie aussi son éveil (`sensor.microduck_eveil`, pas seulement
  l'énergie) et les habitants qu'il sait présents (`sensor.microduck_habitants_presents`). Tout testé
  (27 tests automatisés), rien côté entraînement RL/GPU.

- **2026-10-05 soir → 2026-10-06, sessions cloud (sans PC ni GPU)** : tout ce qui pouvait être écrit sans robot ni
  simulateur l'a été, dans `microduck-brain`. **Rien n'a encore été essayé dans `duck-sim`**, la validation est groupée.
  - **Deux règles d'identité, vérifiées par des tests** :
    - le canard ne s'exprime qu'avec ses 7 sons de canard, jamais de mots ;
    - tout est analysé sur le canard lui-même ; seul Home Assistant reçoit des états. D'où l'abandon de quacksat
      au profit de commandes vocales hors ligne (Vosk).
  - **Toute la vie de M9** (les 16 états du modèle Pollen) :
    - personnalité qui évolue avec la vie du canard, saisons, rythme de la journée ;
    - voix personnelle qui change doucement ;
    - jeu de balle autonome, cache-cache, 1-2-3 soleil, danse au rythme (avec toi s'il te voit bouger en rythme).
  - **Il te remarque et réagit** :
    - accueil, main tendue, caresse ;
    - ton grondeur ou câlin quand on dit son nom ;
    - timidité avec un visiteur, discrétion pendant un appel ;
    - bâillement contagieux, retrait quand c'est trop bruyant, abri pendant les pétards.
  - **Taquineries** avec un budget, un signal « stop » et une mémoire des blagues.
  - **Il surveille sa propre santé** :
    - batterie dans la durée, usure des servos, journal des chutes ;
    - auto-test chaque matin ;
    - tout est publié dans Home Assistant.
  - **Home Assistant dans les deux sens** :
    - la maison lui parle : impressions, sonnette, machines, météo, calendrier, fumée ;
    - lui déclenche des scènes : allumer l'entrée quand tu rentres, scène « nuit » à sa sieste du soir, « canard,
      lumière du salon » à la voix ;
    - mode garde quand la maison est vide, journal de bord du jour.
  - **Qualité** :
    - 295 tests automatiques ;
    - quatre relectures du code, dont la tienne : une quarantaine de défauts réels corrigés, plusieurs touchant à la
      sécurité (vides, alarme incendie, plantages sur données manquantes) ;
    - coût mesuré : 0,03 ms par trame pour un budget de 20 ms.
  - **Application Microduck** : une appli pour téléphone servie par le canard lui-même, sans Home Assistant. Elle a
    7 sections : accueil, jeux, télécommande avec garde-fous, santé avec **diagnostic à la demande**, caractère,
    réglages, journal. À activer avec un code dans `ha.toml` (`[appli]`).
  - **Validation préparée** : une seule commande sur le PC (`valider-tout.sh`) lance les tests, le banc de coût et
    13 scénarios dans `duck-sim`, puis écrit un rapport.
- **Application Microduck complète (2026-10-07)**, avec ou sans Home Assistant. 358 tests.
  - **Android** : APK 1.8, publié par GitHub avec ta clé à chaque version.
    Lien : <https://github.com/RaphaelGrj/microduck-brain/releases/latest/download/microduck.apk>
  - **Ordinateur** (Windows, Mac, Linux) : release `ordinateur-v*`.
  - **iPhone** : démo en ligne <https://raphaelgrj.github.io/microduck-brain/?demo> (Safari → « Sur l'écran
    d'accueil »). Sur le canard, même chose par son adresse.
  - **Fonctions** : installation depuis le téléphone, messages, vacances, journal et mode photo, jeux sur sa carte,
    usure des servos, carnet d'entretien, invités, imprimantes, studio de chorégraphies.
  - **Design 3D** : code couleur, couleurs gardées, schémas partagés.
  - **Catalogue** `microduck-catalogue` : pièces (avec G-code pour la Prusa), chorégraphies et schémas de couleurs.
  - Les trois dépôts sont fusionnés dans `main` (`develop` pour `microduck_rl`).
- **Lot 9 (2026-10-07), APK 1.4.** 365 tests.
  - **Minuteurs, rappels à heure fixe, réveil doux** : signalés en sons de canard, arrêtés d'une caresse.
  - **Graphique d'humeur et bilan du mois** : le bilan s'enregistre en image.
  - **Android** : raccourcis de l'icône, sauvegarde automatique chaque semaine.
  - **Home Assistant** : carte de tableau de bord `homeassistant/microduck-card.js`.

- **Canard plus vivant (2026-10-07), APK 1.5.** 379 tests, à valider dans `duck-sim`.
  - Il respire et bouge les yeux au repos, s'habitue aux bruits répétés, répond en sons quand on lui parle.
  - Il boude puis se réconcilie, est jaloux quand on caresse le chat, attend à la porte à l'heure de ton retour.
  - Il se souvient des bons et mauvais endroits, il vieillit (timide au début, de plus en plus sûr de ses blagues,
    toujours maladroit).
  - Suis-moi / je te suis, et il trépigne quand tu soulèves la balle.
  - Gestes du corps (saut de joie, se gratter, s'allonger) : à entraîner sur le GPU.

- **Son personnage (2026-10-07), APK 1.6.** 396 tests, à valider dans `duck-sim`.
  - Hoquet, petites gaffes vexées, deux tours avant la sieste, tour de victoire ou tête basse au jeu de balle.
  - Il refait ce qui vous fait rire, réclame le câlin à l'heure habituelle, picore les objets nouveaux, garde son
    doudou (la balle).
  - Il rejoue le rythme que tu tapes, a un « nom » sonore pour chacun, se fait petit quand ça crie, rit avec vous,
    va prendre le soleil.

- **Vivant III (2026-10-07), APK 1.7.** 403 tests, à valider dans `duck-sim`.
  - Ses goûts musicaux et « sa chanson », une humeur différente chaque jour, besoin de solitude après la foule.
  - Des rêves qui rejouent sa journée, son anniversaire, la sieste près du chat.
- **Plan de la maison (Meta Quest 3), APK 1.8.** 410 tests.
  - Appli Quest (Unity) et pas-à-pas : `microduck-brain/quest/README.md`.
  - Un plan par lieu (déménagement = nouveau scan), importé et vu dans l'appli ; aperçu PNG sur le PC.
  - Le canard s'y situe : 8 cm en moyenne au banc synthétique, s'il part de son chargeur. Marqueurs imprimés pour se
    retrouver ailleurs.
  - Pas encore branché dans le cerveau, ni essayé dans `duck-sim`.

## En cours — l'apprentissage (en pause, reprise possible)

- **Tir tolérant du pied gauche** : arrêté à l'itération 1 750 sur 3 000 (point de reprise conservé).
- **Passe douce** (balle à 0,5 m/s pour le chat ou toi) : préparée, à entraîner ensuite (accord donné).

## À faire

0. **GitHub Pages** : Settings → Pages → Source = « GitHub Actions », puis Actions → Pages → Run workflow (la démo
   iPhone n'est pas encore en ligne sans ce réglage). Exporter les schémas de la démo de l'ancienne appli avant de la
   désinstaller, puis installer l'APK de GitHub.
1. **Sur ton PC** :
   - `git pull` de `main` dans `~/microduck-brain` ;
   - lancer la validation groupée : `setsid bash ~/microduck-brain/scripts-wsl/valider-tout.sh > /dev/null 2>&1 < /dev/null &` ;
   - me renvoyer le rapport `~/validation-*.txt`. Je corrige d'après les vrais résultats.
2. **Côté Home Assistant** :
   - reporter dans `ha.toml` ce qui t'intéresse dans `ha.exemple.toml` : scènes déclenchées par le canard, calendrier,
     température extérieure, visiteur, compagnie, repas, mode garde ;
   - PrusaLink pour les Prusa ;
   - Mosquitto si tu veux le MQTT.
3. **GPU** : finir le pied gauche tolérant, entraîner la passe douce, puis rejouer avec le chat et dans l'appartement.
4. **À la livraison du robot** :
   - `bench_cerveau.py` sur le robot ;
   - patchs du micro partagé, déploiement `deploy/robot/` ;
   - étude du NPU (détection de personnes) ;
   - étalonnage des seuils audio et de la caresse.

## Pour reprendre
- **Validation complète** : `bash ~/microduck-brain/scripts-wsl/valider-tout.sh` (ou quelques scénarios : `... valider-tout.sh bec_index autotest`).
- **Simulateur seul** (WSL) : `bash ~/run-scene.sh arena` (autres scènes : `arena_chat`, `testball`, `apartment`).
- **Tests sans simulateur** : `cd ~/microduck-brain && uv run --with pytest pytest -q $(ls test_*.py | grep -v test_chat_affiche)`.
- **Entraînements** : consignes de reprise dans `~/kick_reprise.txt` (WSL) : tir tolérant gauche depuis 1 750, puis passe douce.
- **Home Assistant** : `bash ~/run-brain.sh pont_ha.py ha.toml --verifier`.
