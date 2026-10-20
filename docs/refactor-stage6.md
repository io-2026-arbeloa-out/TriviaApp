# Etap 6 — kontrakty repozytoriów i składanie zależności

Stan po implementacji, 20.10.2026. Zmiany przygotowane do review; nie wykonano commita ani wdrożenia.

## Usunięte warstwy

Po ponownym sprawdzeniu użyć usunięto sześć nieużywanych par: `IGameOptionsService` / `GameOptionsService`, `IPrivateGameCreationService` / `PrivateGameCreationService`, `IPrivateGameJoinService` / `PrivateGameJoinService`, `ISingleplayerScoreTableService` / `SingleplayerScoreTableService`, `IAchievementService` / `AchievementService`, `ILeaderboardService` / `LeaderboardService`.

Cztery aktywne przepływy korzystają teraz bezpośrednio z kontraktów w `lib/repositories`:

- Lista quizów: `QuizRepository`, implementowany przez `FirebaseQuizRepository`; usunięto `IQuizListService` i `QuizListService`.
- Profil: `ProfileRepository`, implementowany przez `FirebaseProfileRepository`; obejmuje profil i odczyt wybranego presetu. Usunięto `IProfileDataService` i `ProfileDataService`.
- Opcje: `OptionsRepository`, implementowany przez `FirebaseOptionsRepository`; jeden kontrakt dla dźwięku i presetów, używany przez ekrany oraz `UIOptionsService`. Usunięto `IUserOptionsService` i `UserOptionsService`.
- Logowanie: `AuthRepository`, implementowany przez `FirebaseAuthRepository`; logowanie, rejestracja, nazwa użytkownika, wylogowanie, strumień i prosty stan zalogowania. Usunięto `ILoginAuthService` i `AuthLoginService`.

Kontrakty opisują dane aplikacji i nie ujawniają obiektów SDK Firebase. Fake testowe implementują kontrakty repozytoriów. Wylogowanie z profilu także korzysta z przekazanego repozytorium Auth.

Zachowano pięć serwisów i ich kontraktów: multiplayer connection/game, singleplayer game, rejestracja i wybór wyglądu. Rejestracja nadal koordynuje Auth oraz profil i zachowuje możliwość ponowienia po częściowej porażce. `UIOptionsService` nadal łączy wybrany preset profilu z repozytorium opcji i obsługuje lokalny preset domyślny.

Bilans uzgodnionego zakresu: usunięto 10 interfejsów i 10 serwisów, dodano 4 kontrakty repozytoriów. Pozostało 5 kontraktów serwisów, łącznie 9 kontraktów zamiast 15.

## Składanie zależności

`lib/app_dependencies.dart` składa repozytoria i serwisy. Obsługuje przekazane klienty Auth, Firestore, RTDB i Functions oraz cztery kontrakty repozytoriów. Zależności są tworzone leniwie, więc użycie np. profilu nie tworzy przy okazji repozytorium pytań czy transportu Functions.

`TriviaApp` może otrzymać własne `AppDependencies`. Router przekazuje je do aktywnych przepływów; menu i lobby przekazują ten sam graf dalej. Ekrany zachowują możliwość bezpośredniego wstrzyknięcia swoich zależności w testach. Domyślny graf jest tworzony przy użyciu aplikacji, a klienci Firebase dopiero przy odczycie potrzebnej zależności.

Każdy formularz rejestracji otrzymuje nowy `AuthRegisterService`, aby stan ponowienia nie przechodził do innego formularza. Repozytoria i bezstanowy serwis wyglądu są współdzielone w obrębie grafu.

Poprawiono również konstrukcję domyślnego repozytorium sesji w `MultiplayerGameService`: jeśli przekazano Firestore, otrzymuje go również repozytorium zagnieżdżone. Osobny test potwierdza tę ścieżkę bez uruchamiania domyślnego Firebase.

Nie zmieniano schematu danych, reguł bezpieczeństwa, backendu ani mechaniki gry. Typowane snapshoty, kontrolery ekranów i dalsze oddzielenie prezentacji rozgrywki od SDK pozostają zakresem etapu 7. Ekrany i repozytoria prototypowych osiągnięć/rankingu zachowano; usunięto wyłącznie nieużywane warstwy serwisów.

## Weryfikacja

- Pełny zestaw przed zmianami: 344 zaliczone testy Fluttera.
- Pełny zestaw po zmianach: 342 zaliczone testy (`flutter test --no-pub`).
- Usunięto 17 testów wyłącznie delegowania przez nieistniejące już serwisy (dwa pliki serwisów oraz dwa przypadki opcji). Testy repozytoriów, błędów ekranów, profilu i rejestracji pozostały na właściwych granicach.
- Dodano 15 testów: pięć tras na podstawionym Firebase, pełny graf rejestracji/profilu/presetów, osobne instancje rejestracji, repozytorium quizów, wybór quizu i ponowienie po błędzie, zapis ustawień oraz jego błąd, wylogowanie i zagnieżdżony Firestore multiplayera.
- `dart analyze lib test`: zero błędów, 172 pozostałe ostrzeżenia/informacje. Nie wyciszano reguł; porządki pozostałych uwag należą do etapu 8.
- W `lib` i `test` nie ma odwołań do usuniętych kontraktów ani serwisów.

Nie uruchamiano ponownie emulatorów backendu — ten etap nie zmienia funkcji, reguł ani protokołu komend. Nie wykonano próby dwóch klientów w chmurze; pozostaje ona elementem etapu 8.

Historyczne diagramy w `docs/zadanie4` oznaczono jako wcześniejszy projekt architektury. Nie opisują już bieżącego składu klas; ich pełna aktualizacja pozostaje w etapie dokumentacyjnym.
