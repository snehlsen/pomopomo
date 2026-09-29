# 14: Mark Done safeguards

**What to build:** Done is final, but Mark Done has no confirmation, and the only warning is a tooltip on the ⋯ button. It can also be used on a Task whose Pomodoro is Running or Paused, which leaves that Pomodoro counting down on a Done Task. Mark Done should confirm (or offer Undo) and shouldn't be possible while a Pomodoro on the Task is unfinished.

**Blocked by:** None (can start immediately)

**Status:** done

- [ ] Marking a Task Done asks for confirmation, or offers a short Undo, and says that no more Pomodoros can start on it.
- [ ] Mark Done is unavailable while a Pomodoro on that Task is Running or Paused, with a visible reason.
- [ ] The core refuses to mark a Task Done while a Pomodoro on it is Running or Paused, with an error message in the app's usual wording.
- [ ] Automated tests cover the refusal.
