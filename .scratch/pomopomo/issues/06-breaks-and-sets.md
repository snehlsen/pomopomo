# 06: Breaks and Sets

**What to build:** After a Pomodoro is Completed, the app offers the Break that's due: a Short Break, or a Long Break when that Pomodoro ends a Set. You start the Break yourself. The countdown shows in the menu bar, and when it ends a notification appears and a sound plays. The count of Pomodoros toward a Set runs from the start of the Day across all Tasks. Only Completed Pomodoros count, and gaps between Pomodoros don't reset it. A Break keeps counting down while the Mac sleeps. Use the book's default lengths for now: Short Break 5 minutes, Long Break 15 minutes, Set size 4.

**Blocked by:** 01 (walking skeleton)

**Status:** ready-for-agent

- [ ] After a Completed Pomodoro, the due Break (Short or Long) is offered but doesn't start automatically.
- [ ] Every fourth Completed Pomodoro in a Day is followed by a Long Break, counted across all Tasks. Voided and Paused Pomodoros don't count.
- [ ] A Running Break shows its countdown in the menu bar.
- [ ] When a Break ends, a notification appears and a sound plays. You start the next Pomodoro yourself.
- [ ] A Break's countdown follows the real clock, so it keeps running while the Mac sleeps.
- [ ] Automated tests cover counting toward a Set, including gaps, Voided Pomodoros and multiple Tasks.
