---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# passe-droite

Passe douce du pied droit (balle a 0,5 m/s environ, cap a moins de 35 degres). Fenetre de succes mesuree dans duck-sim : balle de 5 a 10 cm en avant du tronc, plus ou moins 2,5 cm lateralement. Validee en simulation uniquement.

A **episodic** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Runs 0.5 s and returns itself to a standing pose.

## Run it on a robot

```bash
sudo robotctl policy add passe-droite RaphaelGrj/microduck-passe-droite
robotctl robot do passe-droite
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `bcaf8d47c`
- exported from a checkout with uncommitted changes
