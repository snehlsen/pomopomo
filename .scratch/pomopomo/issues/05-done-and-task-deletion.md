# 05: Done and Task deletion

**What to build:** You can mark a Task Done yourself at any point, whether it used fewer Pomodoros than its Estimate or more. Done is final: no more Pomodoros can start on a Done Task, and extra work goes into a new Task. You can delete a Task only until its first Pomodoro starts. After that it stays on the Day for good.

**Blocked by:** 01 (walking skeleton)

**Status:** ready-for-agent

- [ ] A Task can be marked Done at any time.
- [ ] A Task never becomes Done on its own, including when it reaches its Estimate.
- [ ] A Done Task can't be undone, and no Pomodoro can start on it.
- [ ] A Task with no started Pomodoros can be deleted.
- [ ] A Task with any started Pomodoro, including a Voided one, can't be deleted.
- [ ] Automated tests cover the rules for Done and deletion.
