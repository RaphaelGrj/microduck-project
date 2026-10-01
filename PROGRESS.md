# Progression — Projet Microduck

> Vue d'ensemble rapide. Détails complets : `ROADMAP.md`. Contexte technique : `CLAUDE.md`.
> Dernière mise à jour : 2026-10-01.

## Fait

- **Environnement de dev opérationnel** : Windows/WSL2/CUDA, synchronisé via GitHub avec
  un laptop Linux (soumission de jobs sur GPU Hugging Face) et avec le robot lui-même à terme.
- **Pipeline d'entraînement RL maîtrisé** : entraîner, visualiser, exporter en ONNX, publier —
  le cycle complet a été fait et validé.
- **`duck-sim` opérationnel** : les vrais logiciels qui tourneront sur le robot (contrôle,
  capteurs, mise à jour) tournent dès maintenant contre un canard simulé — pas besoin d'attendre
  la livraison pour développer dessus.
- **Première brique du « cerveau »** : un script qui pilote le canard simulé à distance via
  son API réseau, indépendamment du code d'entraînement (futur repo dédié).
- **Gestes simples ajoutés** (non, oui, curieux) — sans aucun entraînement, juste du pilotage
  direct de la tête.
- **Simulateur officiel en ligne découvert** : permet de tester les compétences déjà fournies
  par le fabricant (marche, assis/debout, tirs...) depuis n'importe quel navigateur, y compris
  un téléphone — inutile de réentraîner ce qui existe déjà.

## En cours — l'apprentissage

**Compétence visée : se relever tout seul après une chute**, sur sol irrégulier, en résistant
aux bousculades (pensé pour un chat qui le pousserait).

- Avancement : **itération 2000 sur 15000**, mis en pause ce soir.
- Déjà acquis à ce stade : il se redresse et tient debout correctement de façon fiable.
- Reste à voir : tenue face à des bousculades plus fortes (le curriculum monte en intensité).
- Reprise prête — une seule commande à relancer quand on veut continuer.

## À faire

- Reprendre/terminer l'entraînement du relevé, puis durcir l'épreuve des bousculades.
- Caméra sur `duck-sim` (actuellement bloquée côté technique, pas urgent).
- Gestes plus riches (content, surpris, fatigué) — probablement entraînement RL nécessaire.
- **Le vrai projet « jeu de balle »** : détection de la balle par la caméra + logique
  d'approche/tir (le gros morceau restant).
- Intégration Home Assistant (notifications, scènes déclenchées par le robot).
- Le cerveau comportemental complet (au-delà du script actuel) — personnalité, humeur, mémoire.
