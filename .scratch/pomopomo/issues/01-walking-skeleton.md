# 01: Walking skeleton: one Task, one Pomodoro

**What to build:** A native macOS menu-bar app (see ADR 0002) where you can add a Task with an Estimate to today's list and start a Pomodoro on it. The countdown shows in the menu bar. When the Pomodoro's length is up, it becomes Completed, a notification appears and a sound plays. The Task shows how many Pomodoros are Completed against its Estimate. Everything is stored locally and survives relaunching the app.

This ticket sets up the structure every later ticket builds on: the menu-bar app, local storage, and the Day / Task / Pomodoro model using the terms in CONTEXT.md.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The app runs as a menu-bar app, with no Dock icon.
- [ ] You can add a Task with a name and an Estimate (at least 1) to today's Day.
- [ ] You can start a Pomodoro only on a Task. Every Pomodoro belongs to exactly one Task.
- [ ] The menu bar shows the remaining time of the Running Pomodoro.
- [ ] Remaining time is worked out from a stored end time, not by counting down tick by tick, so it stays correct if the app is slow to update.
- [ ] When time is up, the Pomodoro becomes Completed, with a system notification and a sound.
- [ ] Each Task shows its Completed Pomodoros against its Estimate.
- [ ] Tasks and Pomodoros survive quitting and relaunching the app.
- [ ] Automated tests cover the Pomodoro going from Running to Completed, using a clock the tests control.
