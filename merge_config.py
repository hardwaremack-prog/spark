"""After an update: keep the config.json settings you changed, take new defaults for the rest."""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
mine_p = os.path.join(HERE, "data", "config.before-update.json")
new_p = os.path.join(HERE, "config.json")
defaults_p = os.path.join(HERE, "data", "config.defaults.json")

if os.path.exists(mine_p):
    mine = json.load(open(mine_p, encoding="utf-8"))
    new = json.load(open(new_p, encoding="utf-8"))
    old_defaults = json.load(open(defaults_p, encoding="utf-8")) if os.path.exists(defaults_p) else None
    fresh_defaults = dict(new)
    for k, v in mine.items():
        if k in ("models_to_install", "voices_to_install", "update_repo") or k not in new:
            continue
        if old_defaults is None or old_defaults.get(k) != v:  # you changed it
            new[k] = v
    json.dump(new, open(new_p, "w", encoding="utf-8"), indent=2)
    json.dump(fresh_defaults, open(defaults_p, "w", encoding="utf-8"), indent=2)
