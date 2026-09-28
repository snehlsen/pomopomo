# Pomopomo

A Pomodoro Technique app that follows Francesco Cirillo's method as the book describes it, relaxed in a few deliberate places.

## Language

**Day**:
One calendar day. Each Day starts empty. A Day ends at midnight, unless a Pomodoro is Running then: in that case the Day stays open until that Pomodoro is Completed, Voided or Paused. Past Days are read-only: they stay exactly as they were left, including any Pomodoro still Paused when the Day ended.
_Avoid_: Workday, session, shift

**Pomodoro**:
One block of focused work, 25 minutes by default, on a single Task. It keeps the length it started with, even if the setting changes while it runs. Every Pomodoro belongs to exactly one Task, chosen when it starts. This is the basic unit the method counts in. At any moment it is in exactly one state: Running, Paused, Completed or Voided.
_Avoid_: Slot, session, timer, focus block, interval

### Breaks

**Break**:
Timed rest after a Completed Pomodoro, started by you. It is either a Short Break or a Long Break, and like a Pomodoro it keeps the length it started with. A Break belongs to the Day of the Pomodoro before it and never carries over into a new Day: a Pomodoro Completed after midnight on the Day before is offered no Break, and a Break skipped or ended early across midnight leaves no Skipped-Break Mark on the new Day.
_Avoid_: Pause (Paused is a Pomodoro state), rest, recess

**Short Break**:
A Break, 5 minutes by default, after a Completed Pomodoro.

**Long Break**:
A Break, 15 minutes by default, that takes the place of a Short Break after the last Pomodoro of a Set.

**Set**:
A run of Completed Pomodoros, four by default, within a Day, counted from the start of the Day across all Tasks. Voided and Paused Pomodoros don't count, and gaps between Pomodoros don't reset the count. A skipped Long Break doesn't carry over: the next Set simply begins.
_Avoid_: Round, cycle, block

### Tasks

**Task**:
One item on a Day's task list, worked on in Pomodoros. A Task belongs to exactly one Day. If it isn't done when that Day ends, it stays there. To keep working on it, you add it again on a later Day with a new Estimate. A Task can be deleted only until the first Pomodoro on it starts.
_Avoid_: To-do, item, activity, ticket

**Estimate**:
The number of Pomodoros you expect a Task to take, set when you add the Task. You can change it until the first Pomodoro on that Task starts, even if that Pomodoro is later Voided. After that it is locked. It's fine to use fewer than the Estimate.
_Avoid_: Budget, quota, target, allocation

**Done**:
A Task you have marked as finished yourself. Done is final: no more Pomodoros can be started on a Done Task, so extra work goes into a new Task. A Task never becomes Done on its own, whether it used fewer Pomodoros than its Estimate or more.
_Avoid_: Completed (that word is for Pomodoros), closed, resolved

### Pomodoro states

**Running**:
The Pomodoro's countdown is ticking.

**Paused**:
The countdown is stopped and can be picked up from where it stopped. You can pause a Pomodoro yourself, and it is also Paused automatically when the computer goes to sleep. If a Pomodoro is still Paused when its Day ends, it stays Paused for good and counts toward nothing.
_Avoid_: Interrupted (the book uses "interrupted" for something else)

**Completed**:
The Pomodoro's full length of work is done. Only Completed Pomodoros count.
_Avoid_: Finished, successful, done (Done is for Tasks)

**Voided**:
Abandoned before its full length of work was done, either on purpose or because a new Pomodoro was started while this one was Paused. A Day has at most one Pomodoro that is Running or Paused at a time. A Voided Pomodoro stays in the Day's history, but it counts toward nothing.
_Avoid_: Cancelled, discarded, failed, broken

### Marks

**Mark**:
A visible label on a Pomodoro recording that one of the method's rules was bent. Marks are only for information and never change what counts. Every kind of Mark looks clearly different from the others, and a Pomodoro can carry several.
_Avoid_: Flag, badge, penalty, strike

**Pause Mark**:
A Mark on a Pomodoro that was Paused at least once before it was Completed.
_Avoid_: Paused Pomodoro (Paused is a state, not a Mark)

**Overrun Mark**:
A Mark on a Pomodoro that went beyond its Task's Estimate.
_Avoid_: Extra Pomodoro, over-budget

**Skipped-Break Mark**:
A Mark on a Pomodoro that was started when a Break was due and that Break was skipped or ended before its time was up.
_Avoid_: No-break, back-to-back
