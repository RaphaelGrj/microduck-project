# Progression — Projet Microduck

> Vue d'ensemble rapide. Détails complets : `ROADMAP.md`. Contexte technique : `CLAUDE.md`.
> Dernière mise à jour : 2026-10-03 (soir).

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
- **Simulateur officiel en ligne découvert** (essai des compétences du fabricant depuis un
  navigateur).

## En cours — l'apprentissage

**Compétence visée : se relever tout seul après une chute**, sur sol irrégulier, en résistant
aux bousculades (pensé pour un chat qui le pousserait).

- **Arrêté à 18 h le 2026-10-03** à ≈ l'itération 7 000 (sur 17 000 prévues) ; la récompense stagne depuis l'itération 4 500
  (≈ 47) et le canard ne tombe plus dans les situations testées. Reprise prévue jusqu'à 10 000 puis évaluation (GPU libre d'ici là).
- Déjà acquis : il se redresse et tient debout de façon fiable.

## À faire

- **Décision à prendre : réentraîner le tir avec une position de balle beaucoup plus tolérante**
  (aujourd'hui ±3 cm : le canard doit se placer au centimètre et son propre pied pousse la
  balle). Demande du GPU (ou Hugging Face Jobs) ; le GPU est déjà occupé par le relevé.
- Terminer / durcir l'apprentissage du relevé.
- Jeu de balle : viser une cible (le tir part à ±20° de l'axe), balle dans le dos, pièce
  encombrée, **chat** (détection par réseau pré-entraîné, la couleur ne suffira pas).
- Gestes plus riches (content) — probablement entraînement RL nécessaire.
- **Chat** : l'affiche de ton chat est détectée dans la simulation (0,90, position à 2 cm) ; reste la veille dans le cerveau.
- **Home Assistant** : brancher sur ta vraie instance (URL, jeton, noms d'entités), puis MQTT et scènes déclenchées par le robot.
- Le cerveau comportemental complet — personnalité, humeur, mémoire.

## Pour reprendre demain (tout est arrêté ce soir)
- **Simulateur** (WSL) : `bash ~/run-scene.sh arena_chat` (≈ 1,5 min ; autres scènes : `arena`, `testball`, `apartment`).
- **Tests sans simulateur** : `bash ~/run-brain.sh test_ha.py` (pont Home Assistant), `test_chat.py` (veille du chat).
- **Démos dans le simulateur** : `demo_chat.py` (le canard réagit à l'affiche du chat), `demo_ha.py`, `approach_eval.py` (balle).
- **Entraînement StandUp** : consignes de reprise dans `~/standup_reprise.txt` (WSL) ; objectif 10 000 itérations puis évaluation.
- **Home Assistant** : remplir `ha.toml` (IP du Pi, jeton), puis `bash ~/run-brain.sh pont_ha.py ha.toml --verifier`.
