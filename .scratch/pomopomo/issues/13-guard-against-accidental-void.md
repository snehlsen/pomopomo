# 13: Guard against an accidental Void

**What to build:** Void sits right next to Pause, takes one click and can't be undone, so a slip throws away up to a full Pomodoro of work. Voiding on purpose should stay quick, but a mis-click shouldn't be able to cost work. Either confirm the Void, move it out of the way (e.g. into a "…" menu), or offer a short Undo after it.

**Blocked by:** None (can start immediately)

**Status:** todo

- [ ] A single mis-click next to Pause can't Void a Pomodoro without a chance to back out.
- [ ] Voiding on purpose still takes at most two deliberate steps.
- [ ] If Undo is chosen: undoing restores the Pomodoro to exactly the state it was in (Running with the same end time, or Paused with the same remaining time, with the same Marks).
- [ ] If Undo is chosen, automated tests cover undoing a Void of a Running and of a Paused Pomodoro.
