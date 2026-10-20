# TriviaApp

Aplikacja quizowa w Flutterze z Firebase Auth, Firestore, Realtime Database i Cloud Functions. Walidacja odpowiedzi oraz przebieg multiplayera należą do serwera; także singleplayer wymaga połączenia z backendem.

## Zakres funkcji

- Logowanie i rejestracja z możliwością dokończenia zapisu profilu po częściowym błędzie.
- Singleplayer: wybór kategorii, liczby i typu pytań, zegar, serwerowy feedback oraz lokalna tabela wyniku.
- Publiczny multiplayer oraz prywatne lobby z kodem, konfiguracją gospodarza, eliminacją i losowaniem.
- Wyniki multiplayera w archiwum, naliczanie statystyk przez serwer, odczyt po usunięciu danych roboczych sesji.
- Profil, presety wyglądu i zapis ustawień dźwięku.

Ranking i osiągnięcia są ekranami prototypowymi z przykładowymi danymi. Backend ma logikę rozliczenia trybu rankingowego, ale nie oznacza to gotowego przepływu rankingowego w UI. Muzyka i efekty mają kod oraz zasoby; pełne podłączenie audio nie jest kryterium ukończenia refaktoru.

## Uruchomienie aplikacji

Weryfikacja lokalna: Flutter **3.41.4**, Dart **3.11.1**, Node **24.14.1**, Java **25**. Backend deklaruje runtime Node **20** w `functions/package.json`; workflow CI sprawdza tę wersję. Do Androida potrzebny jest skonfigurowany Android SDK i telefon lub emulator widoczny przez Fluttera.

Z katalogu głównego:

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

Na drugim urządzeniu uruchom drugi proces z jego identyfikatorem. Użyj dwóch osobnych kont. Konfiguracja w `lib/firebase_options.dart` wskazuje projekt `triviaapp-tt`; aplikacja domyślnie korzysta z jego usług chmurowych. Nie traktuj go automatycznie jako środowiska testowego. Własny projekt wymaga osobnej konfiguracji FlutterFire dla wybranych platform oraz przygotowanego backendu i danych.

Emulator Androida emuluje urządzenie, nie Firebase. Obecny `main.dart` nie przełącza usług na lokalne emulatory. Poniższy zestaw emulatorowy służy do automatycznych testów reguł i backendu; nie uruchamia pełnej interaktywnej gry z Auth, callable Functions i Cloud Tasks. Samo `flutter run` nie publikuje nowych funkcji ani reguł.

## Testy i analiza

Testy Fluttera korzystają z fake/mock i nie wymagają uruchomienia produkcyjnego Firebase:

```sh
flutter pub get
dart analyze lib test
flutter test --no-pub
```

Backend — z katalogu `functions`:

```sh
npm ci
npm test
npm run test:security
```

Ostatnia komenda uruchamia Firestore na `127.0.0.1:8080` i RTDB na `127.0.0.1:9000` dla **`demo-triviaapp`**. Porty muszą być wolne, a działające JDK dostępne przez `JAVA_HOME`/`PATH`. Firebase CLI przy pierwszym uruchomieniu może pobrać emulatory. Testy odmawiają uruchomienia bez adresów emulatorów i czyszczą dane projektu demo między przypadkami. Nie uruchamiaj pliku `security.emulator.js` jako testu przeciwko chmurze.

Workflow [CI](.github/workflows/ci.yml) uruchamia analizę, testy Fluttera, jednostkowe testy backendu i testy emulatorowe. Nie wdraża aplikacji ani Firebase i nie wymaga kont produkcyjnych. Lokalny sukces nie jest potwierdzeniem wyniku GitHub Actions — pierwszy przebieg nastąpi po wysłaniu zmian.

## Dane i odpowiedzialności

- **RTDB:** `public_questions/{category}/{id}` zawiera `text`, `answers`, `type`, `difficulty`; `answer_keys/{category}/{id}` zawiera prywatne `correctAnswers`. Klient nie odczytuje kluczy odpowiedzi ani starego drzewa `questions`. ID są tekstem: `01` i `1` to różne pytania. Wartość typu `true_false` pozostaje niezmienna w danych, mimo nazwy `QuestionType.trueFalse` w Dart.
- **Firestore:** `users/{uid}` to profil, opcje i statystyki; `quizzes/{id}` to `category` i `title`; `ui_presets/{id}` to presety wyglądu. Sesje multiplayera są w `sessions/{id}` z podkolekcjami `answers` i `roundCounters`, wyniki w `sessions_archive/{id}`. `singleplayer_sessions/{id}` przechowuje stan serwerowej walidacji singleplayera.
- Status sesji (`waiting`, `inProgress`, `finished`, `aborted`) jest oddzielony od fazy rundy (`answering`, `resolving`, `finished`). Koniec gry dla klienta wymaga `resultsReady`; archiwum po cleanupie wymaga potwierdzenia `statsApplied`.
- `AppDependencies` składa zależności. Repozytoria obsługują dane; serwisy koordynują operacje; kontrolery posiadają stan i lifecycle rozgrywki; ekrany zajmują się prezentacją, animacjami, nawigacją i komunikatami.
- Cloud Functions w `europe-central2` sprawdzają tożsamość i komendy. Triggery oraz kolejki `roundTimeoutQueue`, `roundAdvanceQueue`, `sessionCleanupQueue` prowadzą rundy, finalizację i cleanup. Klient nie zapisuje samodzielnie wyników ani statystyk.

Diagramy i przepływy: [aktualna architektura](docs/architecture.md). Starsze dokumenty `docs/zadanie*` zachowują kontekst projektu uczelnianego.

## Przed wdrożeniem

Przygotuj bank pytań i klucze zgodnie z [migracją etapu 4](docs/refactor-stage4.md), backend i zadania zgodnie z [etapem 5](docs/refactor-stage5.md). Nowe reguły, backend i klient wymagają uzgodnionej zmiany; nie mieszaj starego i nowego przebiegu sesji.

Próby dwóch urządzeń, ponowień Cloud Tasks oraz decyzje dotyczące historycznych danych opisuje [checklista weryfikacji](docs/manual-verification.md). Nie wykonano ich w ramach lokalnej weryfikacji etapu 8. Znane ograniczenia obejmują brak automatycznego wznowienia aktywnej gry po restarcie aplikacji, retencję sesji singleplayer i zastane podatności zależności npm opisane w etapie 4. Nie wykonano automatycznej aktualizacji głównych wersji zależności.
