# Microduck — un droïde de compagnie à la maison

Projet personnel autour du **[Microduck](https://github.com/pollen-robotics/microduck)** de Pollen Robotics : un
petit robot bipède d'environ 25 cm et 800 g, dont tout le logiciel est ouvert (Apache-2.0).

Le but n'est pas une démo, mais **un membre du foyer façon droïde Star Wars** :
- une présence autonome ;
- une personnalité qui se tient dans le temps ;
- des réactions physiques et sonores ;
- une place dans la maison connectée (Home Assistant).

Le canard ne parle jamais avec des mots : il s'exprime uniquement avec ses sons de canard.

> **État** : robot commandé, pas encore livré. Tout est développé et testé en simulation, avec `duck-sim`, les vrais
> logiciels du robot qui pilotent un canard MuJoCo.

## Les trois dépôts

| Dépôt | Rôle |
|---|---|
| **microduck-project** (celui-ci) | Le carnet de bord : objectifs, feuille de route, avancement, notes techniques. Aucun code. |
| [**microduck-brain**](https://github.com/RaphaelGrj/microduck-brain) | Le **cerveau** du canard : comportement, perception (caméra, distance, son), pont Home Assistant. Python, tourne **sur** le robot. |
| [**microduck_rl**](https://github.com/RaphaelGrj/microduck_rl) | Fork de l'entraînement officiel (RL, mjlab + PPO) : nouvelles tâches de tir, scènes de test et outils pour `duck-sim`. |

## Les deux projets prioritaires

1. **Un vrai jeu de balle.** Le tir officiel est « aveugle » : il frappe une balle placée à un endroit fixe. Ici, le
   canard repère la balle avec sa caméra, va jusqu'à elle, se place et tire, ou la passe au chat.
2. **Home Assistant dans les deux sens.**
   - La maison prévient le canard : fin ou échec d'impression 3D, sonnette, machines, météo, alarme incendie.
   - Le canard renseigne la maison : son état, sa batterie, sa santé, et une alerte de garde quand la maison est vide.
   - Il déclenche des scènes : accueil, nuit, commandes vocales reconnues sur le robot lui-même.

## Les documents

| Fichier | Contenu |
|---|---|
| [`PROGRESS.md`](PROGRESS.md) | **Commencer ici** : vue d'ensemble en langage simple (fait, en cours, à faire, comment reprendre). |
| [`ROADMAP.md`](ROADMAP.md) | La feuille de route complète : idées, priorités, tableau de synthèse, et le journal détaillé de chaque session. |
| [`CLAUDE.md`](CLAUDE.md) | Le contexte technique : environnement de développement, API `robotd`, pièges connus, état d'avancement. Sert aussi de mémoire de travail à Claude Code. |
| [`docs/`](docs) | Notes ponctuelles (ex. un défaut du simulateur signalé à l'amont). |

## Les règles du projet

- **Le canard ne s'exprime qu'avec ses sons de canard** (`alarm`, `greet`, `inquire`, `peck`, `chirp`, `coo`,
  `wheee`) : pas de voix humaine, pas de synthèse vocale.
- **Tout tourne sur le canard.** Aucun autre appareil n'analyse ses images, ses sons ou ses mesures. Home Assistant
  reçoit des états et envoie les événements de la maison, rien de plus.
- **La sécurité d'abord.** Il ne marche jamais sans son capteur de distance, ni vers un vide. L'alarme incendie
  passe avant tout.
- **Pas de secrets dans les dépôts.** La configuration locale `ha.toml` (jeton Home Assistant), les photos et les
  modèles restent hors de Git.

## Matériel et environnement

- Robot : Microduck (Pollen Robotics), livré avec 2 batteries de rechange.
- Développement : Windows 11 + WSL2 (Ubuntu), GPU NVIDIA RTX 5070 Ti pour l'entraînement.
- Maison : Home Assistant OS sur Raspberry Pi 3B+, deux Prusa (MK3S → MK4S), une Elegoo Saturn 4 Ultra.
