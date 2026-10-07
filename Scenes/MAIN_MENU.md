# Main menu

Press F5 to open `main_menu.tscn`. Start enters Floating Town, Controls opens the Thai instructions, and Quit closes the game. The Start button receives keyboard focus; arrow keys navigate and Enter confirms.

In Floating Town, press Esc to release the mouse and click the HUD menu button to return. Starting again creates a fresh level session.

Edit the native interface in `main_menu_ui.tscn` and its actions in `Scripts/MainMenu.gd`. The backdrop contains Aof and a floating street, with no playable character. Rebuild it using `tools/build_main_menu.gd` after changing the source assets.

Headless integration check: run Godot with `--headless --path 3D_Game --script res://tests/main_menu_test.gd --log-file <writable-log-path>`.
