> How do I start a utility like `hyprpaper &` and be able to close the terminal that opened it. So launch a utility that is not tied to a terminal client?

Use `nohup` and `&` together:

```bash
nohup hyprpaper & disown
```

> How does this work? what is nohup? is it possible to just use `hyprpaper & disown`?

`nohup` allows a process to continue running even after the terminal is closed. Without `nohup`, the process can still receive a HUP (hangup) signal when the terminal closes.

`& disown` runs the process in the background and removes it from the shell's job table. Using just `hyprpaper & disown` might work in many cases, but if the terminal sends a HUP signal, `nohup` provides extra protection.

`nohup hyprpaper & disown` ensures it fully detaches from the terminal.
