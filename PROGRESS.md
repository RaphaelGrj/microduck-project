# Progression — Projet Microduck

> Vue d'ensemble rapide. Détails complets : `ROADMAP.md`. Contexte technique : `CLAUDE.md`.
> Dernière mise à jour : 2026-10-05.

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
  salon » comme entité Home Assistant. Tout testé (24 tests automatisés), rien côté entraînement RL/GPU.

## En cours — l'apprentissage (arrêté ce soir, reprise possible)

- **Tir tolérant du pied gauche** : arrêté à l'itération 1 750 sur 3 000 (point de reprise conservé).
- **Passe douce** (balle à 0,5 m/s pour le chat ou toi) : préparée, à entraîner ensuite (accord donné).

## À faire

- Finir le pied gauche tolérant, entraîner la passe douce, puis rejouer avec le chat et dans l'appartement.
- Mieux mesurer et compenser l'angle de départ de la passe ; détection du chat sur le côté (affiche vue de biais).
- Intégrer le jeu dans le cerveau (proposer de jouer rarement, seulement si le chat est d'humeur).
- **Toi, côté Home Assistant** : intégration PrusaLink (les Prusa ne sont pas dans HA) ; une entrée Interrupteur
  `microduck_calme` ; Mosquitto si tu veux le MQTT.
- À la livraison du robot : voix (quacksat) et carte de la maison (quacknav), puis tout revalider sur le vrai matériel.

## Pour reprendre demain (tout est arrêté ce soir)
- **Simulateur** (WSL) : `bash ~/run-scene.sh arena_chat` (≈ 1,5 min ; autres scènes : `arena`, `testball`, `marche`, `apartment`).
- **Tests sans simulateur** : `bash ~/run-brain.sh test_ha.py` (pont Home Assistant), `test_chat.py` (veille du chat).
- **Démos / bancs** : `jeu_eval.py` (jeu avec le chat), `approach_eval.py` (balle), `essai_vide.py` (marches), `diag_pose.py`.
- **Entraînements** : consignes de reprise dans `~/kick_reprise.txt` (WSL) : tir tolérant gauche depuis 1 750, puis passe douce.
- **Home Assistant** : `ha.toml` rempli (IP, jeton, entités) ; vérification : `bash ~/run-brain.sh pont_ha.py ha.toml --verifier`.
