# 10: Auto-pause on sleep

**What to build:** When the Mac goes to sleep, a Running Pomodoro is Paused automatically, keeping the remaining time it had at that moment. After waking, you resume it or void it yourself. If you resume it and it's later Completed, it carries a Pause Mark like any Pomodoro Paused by hand. This is the only case where the app pauses a Pomodoro on its own. Breaks aren't affected.

**Blocked by:** 02 (pause and resume)

**Status:** ready-for-agent

- [ ] Sleep while a Pomodoro is Running makes it Paused, with the remaining time it had at that moment.
- [ ] After waking, the Pomodoro is still Paused, ready to resume or void.
- [ ] Once Completed, a Pomodoro Paused this way carries a Pause Mark.
- [ ] A Running Break isn't Paused by sleep.
- [ ] Automated tests cover the automatic pause, with the sleep signal simulated.
