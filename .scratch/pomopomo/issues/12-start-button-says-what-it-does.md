# 12: Start button says what it does

**What to build:** Pressing Start can do more than start a Pomodoro, and today the UI only mentions this in a tooltip, or not at all. It voids a Paused Pomodoro, skips a due or Running Break (adding a Skipped-Break Mark), and adds an Overrun Mark once the Task has reached its Estimate. On the row of the Paused Pomodoro's own Task, Start even voids the Pomodoro the user most likely wants to resume. The button should say what it will do before it is pressed.

**Blocked by:** None (can start immediately)

**Status:** todo

- [ ] On the row of the Task whose Pomodoro is Paused, the button is Resume, and it resumes that Pomodoro instead of voiding it.
- [ ] On other rows while a Pomodoro is Paused, the button makes clear that the Paused Pomodoro will be Voided, e.g. "Void & Start" or a confirmation.
- [ ] While a Break is due or Running, the Start button shows visibly (not only as a tooltip) that starting skips the Break and adds a Skipped-Break Mark.
- [ ] When the Task has reached its Estimate, the Start button shows visibly that the next Pomodoro will carry an Overrun Mark.
- [ ] No Start button has an empty tooltip.
