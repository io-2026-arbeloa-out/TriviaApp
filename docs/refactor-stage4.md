# Etap 4 — uprawnienia i serwerowa walidacja odpowiedzi

> Przebieg rund, finalizację i cleanup opisuje teraz [etap 5](refactor-stage5.md). Poniższy dokument zachowuje stan i wyniki weryfikacji etapu 4.

Stan implementacji: 20.10.2026. Zmiany przygotowane do review; nie wdrożono funkcji, reguł ani danych.

## Granice dostępu

- Tożsamość komend pochodzi z Firebase Auth (`request.auth.uid`). Klient nie wybiera użytkownika, którego dane zostaną zmienione.
- Tworzenie, dołączanie, zmiana ustawień, start, wyjście i odpowiedzi multiplayer przechodzą przez callable Cloud Functions w `europe-central2`. Bezpośredni zapis sesji, odpowiedzi i liczników przez klienta jest zabroniony.
- `hostUid` pozostaje niezmienny. Tylko gospodarz oczekującego prywatnego lobby zmienia ustawienia i uruchamia grę. Start ponownie sprawdza `settingsVersion`, liczbę graczy i fazę w transakcji.
- `playerUids` opisuje obecnych uczestników; `participantUids` zachowuje historię dołączeń. Wyjście gospodarza zamyka oczekujące prywatne lobby. Wyjście z aktywnej gry zachowuje dane gracza do wyniku.
- Zalogowany użytkownik może wyszukiwać oczekujące publiczne sesje. Prywatne lobby wymaga serwerowego wyszukania i dołączenia z kodem; klient nie może listować prywatnych sesji.
- Aktywną sesję i archiwum odczytują historyczni uczestnicy, także ci, którzy wyszli. Archiwum zawiera własne `participantUids`, niezależnie od usuniętego dokumentu sesji.
- Własny profil: klient zmienia wyłącznie `username`, `profilePicture`, `user_options`, `ui_options`. Utworzenie profilu wymaga zerowych statystyk i rankingu `unranked`. Zapis preferencji nie nadpisuje serwerowych statystyk.
- Quizy i presety: odczyt po zalogowaniu, zapis wyłącznie administracyjny. Pozostałe nieudostępnione ścieżki pozostają zamknięte.

## Pytania i odpowiedzi

Dotychczasowe `questions/{category}/{id}` zostaje rozdzielone na wspólny bank dla obu trybów:

```text
public_questions/{category}/{id}: {text, answers, type, difficulty}
answer_keys/{category}/{id}: {correctAnswers}
```

Publiczne rekordy nie zawierają etykiet poprawności. Klient po zalogowaniu odczytuje tylko `public_questions`; `answer_keys` i stare `questions` są niedostępne. Klucze kategorii i pytań pozostają tekstem, także `01`. Lista wariantów powstaje przez połączenie, usunięcie duplikatów i sortowanie odpowiedzi, aby pozycja nie zdradzała poprawności; UI dodatkowo ją tasuje.

Serwer dobiera pulę pytań multiplayer. `submitMultiplayerAnswer` sprawdza uczestnictwo, fazę i autorytatywne pytanie sesji, następnie atomowo blokuje wybór i aktualizuje licznik. Zwraca `isCorrect` i `correctAnswers` dopiero po zapisie. Identyczne ponowienie zwraca poprzedni wynik bez ponownego naliczenia; zmiana zablokowanej odpowiedzi jest odrzucana. Po utracie odpowiedzi sieciowej UI ponawia ten sam wybór.

Singleplayer również wymaga połączenia z backendem. `startSingleplayer` tworzy sesję właściciela z wydaną listą pytań; `answerSingleplayer` przyjmuje jedną odpowiedź na bieżący indeks i przesuwa kursor w transakcji. UI czeka na wynik, a przy błędzie blokuje zmianę wyboru i udostępnia ponowienie. Ujawnienie poprawnej odpowiedzi po zatwierdzeniu wyboru jest zamierzonym feedbackiem. Wspólny bank nie zapobiega zapamiętywaniu wcześniej rozwiązanych pytań.

## Przygotowanie migracji i wdrożenia

1. Wykonać kopię danych i przygotować eksport z korzeniem `questions`, zachowując strukturę kategorii i klucze pytań.
2. Lokalnie uruchomić z katalogu `functions`: `node scripts/split_questions.js export.json split.json`. Skrypt nie łączy się z Firebase i odmawia nadpisania istniejącego pliku wynikowego. Sprawdzić wynik przed jakimkolwiek importem; fixture w repo nie jest eksportem produkcji.
3. Zaplanować okno migracji: zakończyć stare lobby/sesje, przygotować nowy bank i klucze przez zaufany proces administracyjny. Plik wynikowy zawiera oba drzewa; nie zastępować nim całego korzenia bazy, w którym mogą być inne dane.
4. Skoordynować publikację backendu, indeksów, reguł obu baz i nowego klienta. Same nowe reguły zablokują starego klienta, a stary backend nie obsługuje nowych komend. Po migracji stare `questions` muszą pozostać niedostępne.
5. Starsze archiwa wymagają zaufanego uzupełnienia `participantUids`, jeśli mają pozostać dostępne. Nie odtwarzać tej listy na podstawie danych dostarczonych przez klienta. Stare sesje bez nowych pól należy zakończyć i utworzyć ponownie.
6. Przed produkcją wykonać próbę na środowisku testowym z rzeczywistym klientem, triggerami i Cloud Tasks. Testy emulatorowe poniżej weryfikują komendy i reguły, nie pełny cykl wdrożonych triggerów.

W tym etapie nie wykonano importu ani deployu. Deadline rund, odporna finalizacja i cleanup pozostają zakresem etapu 5. Retencja nowych sesji singleplayer oraz limity wywołań wymagają ustalenia przed eksploatacją na większą skalę.

## Zależności i weryfikacja

`cloud_functions: 6.2.0` zachowuje obecne wersje Firebase w Flutterze. Lockfile dodaje tylko `cloud_functions`, `cloud_functions_platform_interface` i `cloud_functions_web`. Narzędzia reguł: `@firebase/rules-unit-testing 5.0.2` oraz `firebase 12.19.0`, zgodne z deklarowaną rodziną Node 20. Lokalne testy uruchomiono na Node 24.14.1 i Java 25; nie jest to weryfikacja runtime Node 20 na produkcji.

- 110 testów Fluttera dotyczących zmienionych repozytoriów, usług, profilu, cyklu życia i serwerowego feedbacku singleplayer — zaliczone. Nie uruchamiano całego zestawu UI.
- `cd functions; npm test` — 5 testów kontraktu odpowiedzi.
- `cd functions; npm run test:security` — 14 testów na lokalnych emulatorach Firestore i RTDB, projekt `demo-triviaapp`. Testy odmawiają startu bez zmiennych emulatorów. Wymagane wolne porty 8080/9000 i Java obsługiwana przez Firebase CLI (lokalnie Java 25).
- `dart analyze lib test` — zero błędów, 176 ostrzeżeń/informacji zastanych w projekcie; wynik analizy jako całości nie jest zielony.
- Testy dawnych transakcji klienta, w tym usunięty `private_session_settings_test.dart`, przeniesiono do weryfikacji komend backendu w `functions/test/security.emulator.js`. Testy repozytorium sprawdzają nowy kontrakt wywołań.

`npm audit` nadal raportuje podatności zależności, w tym krytyczną w drzewie runtime. Porównanie z lockfile sprzed zmian potwierdziło, że krytyczne problemy występowały już wcześniej. Nie wykonywano automatycznej aktualizacji głównych wersji SDK ani `audit fix --force`; przegląd zależności wymaga osobnej decyzji.
