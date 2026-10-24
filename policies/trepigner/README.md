---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# trepigner

Trepignement : les pieds se levent a tour de role, sur place, tronc droit.

A **episodic** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Runs 2.0 s and returns itself to a standing pose.

## Run it on a robot

```bash
sudo robotctl policy add trepigner RaphaelGrj/microduck-trepigner
robotctl robot do trepigner
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `7b1709769`
- exported from a checkout with uncommitted changes
