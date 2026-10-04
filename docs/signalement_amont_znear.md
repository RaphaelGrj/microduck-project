# Brouillon de signalement à Pollen Robotics (`pollen-robotics/microduck_rl`) — NON ENVOYÉ

**Titre proposé :** `scene_apartment.xml`: the duck camera cannot see anything closer than ~14 cm (znear scales with model extent)

**Constat.** MuJoCo place le plan de coupe proche de la caméra à `visual/map/znear × stat.extent`. `znear` vaut 0,01
par défaut, et l'étendue du modèle de l'appartement est de ~14,2 m : le plan proche est donc à **14,2 cm**. Dans
l'appartement, tout objet à moins de 14 cm de la caméra de la tête n'est pas dessiné. Une balle au pied du canard est
invisible, alors que la vraie caméra (IMX219) la voit. Dans une petite scène (étendue ~0,5 m) le plan proche est à 0,5 cm
et le problème n'existe pas, d'où une différence de comportement entre scènes.

**Reproduction.**
```python
import mujoco
m = mujoco.MjModel.from_xml_path("src/mjlab_microduck/robot/microduck/scene_apartment.xml")
print(m.vis.map.znear * m.stat.extent)   # ~0.142 m
```
Balle de 7 cm posée à 10-15 cm devant le tronc, tête baissée : rien dans l'image de `GET /frame` (duck-sim).

**Correctif proposé** (une ligne dans `scene_apartment.xml`) :
```xml
<visual><map znear="0.0004" /></visual>   <!-- ~0,6 cm pour une étendue de ~14 m -->
```
Mesuré de notre côté : avec ce réglage, la balle est détectée de 10 à 30 cm devant le canard (erreur de position
0,3 à 0,7 cm). Sur un banc de jeu de balle avec la caméra, le taux de réussite dans l'appartement est passé de 8/20 à 13/20.

**Remarque.** La valeur relative dépend de l'étendue : si d'autres grandes scènes existent, il vaut peut-être mieux la
fixer par scène ou fixer `statistic/extent`.
