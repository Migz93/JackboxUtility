# TV mode (early foundation)

Start the app with `--tv-mode` to open the TV launcher fullscreen. The normal
utility remains unchanged when the flag is not supplied.

For Steam Big Picture on Bazzite, add the built launcher as a non-Steam game,
then create a per-game Steam Input layout:

- D-pad → arrow keys
- A → Enter
- B → Escape

The first TV-mode screen deliberately uses keyboard navigation because Steam
Input provides a stable controller-to-keyboard bridge on Linux. It shows only
owned, non-hidden games and exposes four couch-visible filters: player count,
family-friendly, audience participation, and favourites.

Keyboard/controller navigation:

- D-pad moves through the game grid.
- Pressing up from the first grid row enters the filter row.
- A/Enter toggles a selected filter or launches the highlighted game.
- Pressing down from the filter row returns to the grid.

Native gamepad events are intentionally a later enhancement, after validating
the Steam launch and focus-return behaviour on the target Bazzite machine.
