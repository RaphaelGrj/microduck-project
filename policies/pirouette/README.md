---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# pirouette

Pirouette : un tour sur place puis arret. Installer avec --hold 2.1 ; le twist idle [1,0,0] pendant unwind_s est le signal de freinage.

A **perpetual** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Holds until told otherwise; the daemon drives `command.idle` for 1.0 s before handing back to the gait.

## Run it on a robot

```bash
sudo robotctl policy add pirouette RaphaelGrj/microduck-pirouette --hold <seconds>
robotctl robot do pirouette
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `8a20cdc0f`
- exported from a checkout with uncommitted changes
