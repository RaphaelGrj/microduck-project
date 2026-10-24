---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# pas-de-cote

Pas de cote vers la gauche (12 a 30 cm selon les essais). Installer avec --hold 0.8 ; le twist idle [1,0,0] pendant unwind_s (0,8 s) est le signal de freinage. Valide dans duck-sim (sans chute), simulation uniquement.

A **perpetual** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Holds until told otherwise; the daemon drives `command.idle` for 0.8 s before handing back to the gait.

## Run it on a robot

```bash
sudo robotctl policy add pas-de-cote RaphaelGrj/microduck-pas-de-cote --hold <seconds>
robotctl robot do pas-de-cote
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `cbbf51d49`
- exported from a checkout with uncommitted changes
