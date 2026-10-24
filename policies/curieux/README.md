---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# curieux

Accroupissement curieux : le tronc descend a environ 8 cm, tient la pose puis remonte (1,3 s, pieds au sol, sur place). La politique n'a pas d'horloge : au-dela de 1,3 s elle recommencerait un cycle. Valide dans duck-sim (sans chute), simulation uniquement.

A **episodic** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Runs 1.3 s and returns itself to a standing pose.

## Run it on a robot

```bash
sudo robotctl policy add curieux RaphaelGrj/microduck-curieux
robotctl robot do curieux
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `cbbf51d49`
- exported from a checkout with uncommitted changes
