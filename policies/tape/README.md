---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# tape

Tape du pied : un pied frappe le sol a repetition, l'autre reste pose (environ 7 coups en 1,6 s). Valide dans duck-sim (sans chute), simulation uniquement.

A **episodic** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Runs 1.6 s and returns itself to a standing pose.

## Run it on a robot

```bash
sudo robotctl policy add tape RaphaelGrj/microduck-tape
robotctl robot do tape
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `cbbf51d49`
- exported from a checkout with uncommitted changes
