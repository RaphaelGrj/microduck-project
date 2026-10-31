---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# sprint

Sprint : course en ligne droite a environ 0,6 m/s pendant 1,5 s (marche officielle ~0,4), puis freinage. Installer avec --hold 1.5 ; le twist idle [1,0,0] pendant unwind_s (1,0 s) est le signal d'arret. Valide dans duck-sim (4 essais, 73 a 93 cm, sans chute), simulation uniquement.

A **perpetual** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Holds until told otherwise; the daemon drives `command.idle` for 1.0 s before handing back to the gait.

## Run it on a robot

```bash
sudo robotctl policy add sprint RaphaelGrj/microduck-sprint --hold <seconds>
robotctl robot do sprint
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `7fd621ce1`
- exported from a checkout with uncommitted changes
