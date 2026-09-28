# 11: Adjustable lengths

**What to build:** A settings screen where you can change the Pomodoro length, Short Break length, Long Break length and Set size. The book's values are the defaults: 25, 5, 15 and 4. A Pomodoro or Break keeps the length it started with, so a change applies from the next one. A change to the Set size applies to today's count straight away.

**Blocked by:** 06 (breaks and sets)

**Status:** ready-for-agent

- [ ] The four settings can be changed, and they default to 25 / 5 / 15 / 4.
- [ ] Settings survive relaunching the app.
- [ ] A Running or Paused Pomodoro, or a Running Break, keeps the length it started with when a setting changes.
- [ ] The next Pomodoro or Break uses the new length.
- [ ] Changing the Set size affects the next due Break straight away. For example, after 3 Completed Pomodoros, changing the size from 4 to 3 makes the next Break a Long Break.
- [ ] Automated tests cover when changed settings take effect.
