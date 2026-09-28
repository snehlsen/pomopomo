# 04: Estimate lock and Overrun Mark

**What to build:** You can edit a Task's Estimate until its first Pomodoro starts, even if that Pomodoro is later Voided. After that, the Estimate is locked. Every Pomodoro on a Task beyond its Estimate carries an Overrun Mark that looks clearly different from the Pause Mark. Using fewer Pomodoros than the Estimate is fine and gets no Mark.

**Blocked by:** 01 (walking skeleton)

**Status:** done

- [ ] The Estimate can be edited while no Pomodoro has started on the Task.
- [ ] The Estimate can't be edited once any Pomodoro on the Task has started, including one later Voided.
- [ ] Completed Pomodoros beyond the Estimate carry an Overrun Mark. Those within the Estimate don't.
- [ ] The Overrun Mark looks clearly different from the Pause Mark, and a Pomodoro can show both.
- [ ] Automated tests cover when the Estimate locks and which Pomodoros get an Overrun Mark.
