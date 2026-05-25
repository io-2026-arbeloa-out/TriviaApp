# Multiplayer — manual test checklist

Deploy before testing:

```bash
firebase deploy --only functions,firestore:rules
```

## 1. Full game (2 players)

- [ ] Two devices/accounts, category `general`, `maxPlayers: 2`
- [ ] Both join lobby; game starts automatically
- [ ] Both answer round 1 → `resolving` overlay → round 2 without refresh
- [ ] In Firebase Console: `sessions/{id}/roundCounters/0` has `resolved: true`; no `answers` docs with `roundIndex: 0`

## 2. Wrong answers / elimination

- [ ] Both answer incorrectly → one eliminated (or lottery)
- [ ] `activePlayerCount` decreases; next round `roundCounters/{n}.targetCount` matches active players

## 3. Leave mid-round

- [ ] Player A leaves during round 2 while Player B already answered
- [ ] Round closes for Player B (no infinite wait)
- [ ] `roundCounters` `targetCount` updated after leave

## 4. Archive

- [ ] After game end, `sessions_archive/{id}` exists
- [ ] Score table opens (or snackbar after 5 failed fetches)

## Debug

If a round hangs, inspect `sessions/{id}/roundCounters/{currentQuestionIndex}`:

- `validatedCount` vs `targetCount`
- `resolved` should become `true` after round ends
