---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# tir-droit

Tir tolerant du pied droit, pleine puissance (balle a 0,4 a 0,8 m/s). Tolere une balle de 5 a 10 cm en avant du tronc. Coup de pied spectaculaire : le canard plonge dans le tir et est repris par le gait au bout de 0,5 s ; valide en simulation uniquement, a essayer avec prudence sur le robot reel.

A **episodic** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Runs 0.5 s and returns itself to a standing pose.

## Run it on a robot

```bash
sudo robotctl policy add tir-droit RaphaelGrj/microduck-tir-droit
robotctl robot do tir-droit
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `bcaf8d47c`
- exported from a checkout with uncommitted changes
