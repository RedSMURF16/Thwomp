<h1 align="center">Thwomp</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=GrLWfcWX9Io"><img src="https://img.youtube.com/vi/GrLWfcWX9Io/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
Inspired by Super Mario. This plugin adds a fully dynamic Thwomp system to Counter-Strike 1.6.
Thwomps can be placed, managed and configured during gameplay with runtime control over activation, team access, movement and screen shake effects.
- Create and remove Thwomps during gameplay via an in-game menu
- Three configurable Thwomp sizes with independent models and collision bounds
- Configurable per Thwomp: team access, spawn chance, fall speed and raise speed
- Delayed and timed activation with configurable values for round-based gameplay
- Configurable idle duration after the Thwomp hits the ground
- Optional cooldown before a Thwomp can be activated again
- Configurable screen shake effect based on distance from the Thwomp
- Configurable alert and impact sounds
- Dynamic Thwomp movement with falling, idle and raising states
- Dynamic Thwomp rotation and natural ghost preview placement
- Custom Thwomp setups are saved per map and automatically loaded on every map start

## 💬 Commands
- `say /thwomp` - Opens the Thwomp menu.
- `say_team /thwomp` - Opens the Thwomp menu.
- `thwomp_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# Per-Thwomp settings (defined under each [Thwomp Name] section):
# THWOMP_FLAGS             = a - Active Delay     b - Active Duration     c - Shake
# THWOMP_TEAM              = 0 - None             1 - Terrorist           2 - Counter-Terrorist   3 - Both
# THWOMP_SPAWN_CHANCE      = Thwomp's respawn probability (0.0 - 1.0)
# THWOMP_ACTIVE_DELAY      = Delay in seconds before the Thwomp becomes active at round start
# THWOMP_ACTIVE_DURATION   = Duration of the active state in seconds
# THWOMP_ACTIVE_COOLDOWN   = Cooldown in seconds before the Thwomp becomes active again
# THWOMP_FALL_STRENGTH     = Strength of the Thwomp's fall (MIN - MAX)
# THWOMP_FALL_FREQ         = Frequency of the Thwomp's fall (MIN - MAX)
# THWOMP_IDLE_DURATION     = Duration of the idle state after landing (MIN - MAX)
# THWOMP_RAISE_STRENGTH    = Strength of the Thwomp's raise (MIN - MAX)
# THWOMP_COOLDOWN          = Cooldown in seconds before the Thwomp can be activated again (MIN - MAX)
# THWOMP_SHAKE_DISTANCE    = Distance in units for the shake effect
# THWOMP_SHAKE_AMPLITUDE   = Amplitude of the shake effect
# THWOMP_SHAKE_FREQUENCY   = Frequency of the shake effect
# THWOMP_SHAKE_DURATION    = Duration of the shake effect in seconds
# THWOMP_SOUND_ALERT       = Sound played when the Thwomp is about to fall
# THWOMP_SOUND_SMASH       = Sound played when the Thwomp hits the ground
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```
