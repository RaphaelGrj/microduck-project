---
tags:
- microduck
- robotics
- reinforcement-learning
- onnx
library_name: microduck
pipeline_tag: robotics
---

# startle

Sursaut : le tronc se cabre brievement puis se redresse, pieds au sol, sur place.

A **episodic** policy for the [microduck](https://github.com/pollen-robotics/microduck) (61-D observation, 14 actions, 50 Hz). Runs 1.2 s and returns itself to a standing pose.

## Run it on a robot

```bash
sudo robotctl policy add startle RaphaelGrj/microduck-startle
robotctl robot do startle
```

The observation normalizer is baked into `policy.onnx`; feed raw observations.
`manifest.json` follows schema 2 of the microduck policy manifest (`docs/policy-manifest.md` in the daemon repo).

## Training

- **repo**: `pollen-robotics/microduck_rl`
- **branch**: `develop`
- **commit**: `6b63907a6`
- exported from a checkout with uncommitted changes
