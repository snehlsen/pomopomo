# 02: Pause and resume, with the Pause Mark

**What to build:** You can pause a Running Pomodoro and later resume it from exactly where it stopped. When a Pomodoro that was Paused at least once becomes Completed, it carries a visible Pause Mark. Apart from the mark, it counts exactly like any other Completed Pomodoro. See ADR 0001 for why pausing is allowed.

**Blocked by:** 01 (walking skeleton)

**Status:** ready-for-agent

- [ ] A Running Pomodoro can be Paused. Its remaining time freezes, and the menu bar shows that it's Paused.
- [ ] A Paused Pomodoro can be resumed, and it keeps the remaining time it had when it was Paused.
- [ ] A Pomodoro can be Paused and resumed several times.
- [ ] A Completed Pomodoro that was ever Paused shows a Pause Mark.
- [ ] A Pomodoro with a Pause Mark counts toward its Task exactly like one without.
- [ ] Automated tests cover pausing and resuming (including several pauses) and when the Pause Mark is given.
