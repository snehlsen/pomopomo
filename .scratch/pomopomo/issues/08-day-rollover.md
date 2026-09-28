# 08: Day rollover

**What to build:** A new calendar date starts a new, empty Day, and past Days become read-only. A Pomodoro Running at midnight belongs to the Day it started: that Day stays open until the Pomodoro is Completed, Voided or Paused. A Pomodoro still Paused when its Day ends stays Paused for good and counts toward nothing. The app notices a date change even if it happened while the Mac was asleep. A Task that isn't Done stays on its Day. To continue it, you add it again on a later Day with a new Estimate.

**Blocked by:** 02 (pause and resume)

**Status:** done

- [ ] On a new calendar date, today's list starts empty.
- [ ] A Pomodoro Running across midnight is Completed on the Day it started, and it counts toward that Day's Task and Set.
- [ ] If a Pomodoro Running across midnight is Paused after midnight, its Day ends there and it stays Paused for good.
- [ ] A Pomodoro still Paused when its Day ends can no longer be resumed or voided.
- [ ] Nothing on a past Day can be changed.
- [ ] Waking the Mac on a new date shows a new, empty Day.
- [ ] Automated tests cover the midnight cases, using a clock the tests control.
