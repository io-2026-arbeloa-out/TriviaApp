# Próba przed wdrożeniem

Do wykonania przez właściciela projektu na dwóch telefonach lub emulatorach urządzeń. Stan: **nie wykonano** podczas lokalnych prac etapu 8. Testy automatyczne nie zastępują tej próby.

## Przygotowanie i zapis wyniku

1. Zapisz commit, wersję klienta/backendu, platformy i wersje systemów, identyfikator projektu Firebase oraz datę próby. Upewnij się, że oba klienty korzystają z tego samego uzgodnionego środowiska testowego.
2. Potrzebne są dwa konta z kompletnymi profilami, zgodny backend, reguły i indeksy, co najmniej trzy prawidłowe pytania dla publicznej gry dwóch osób oraz odpowiadające im prywatne klucze. Nie zakładaj, że konfiguracja wskazana w repozytorium ma już wdrożone zmiany.
3. Przed grą zanotuj statystyki obu kont. Zapisuj `sessionId`, indeksy rund, czasy i logi błędów. Wynik każdego scenariusza oznacz jako zaliczony, niezaliczony lub niewykonany, z dowodem i opisem odstępstw.
4. Używaj osobnych kont; ponowne logowanie na dwóch urządzeniach na to samo konto nie jest próbą dwóch graczy. Do sprawdzenia odmowy dostępu potrzebne jest także konto nieuczestniczące w sesji.

Emulator telefonu nadal łączy się z chmurą według `firebase_options.dart`. `npm run test:security` sprawdza odrębny projekt demo na lokalnych emulatorach baz i nie uruchamia interaktywnego backendu dla telefonów.

## Publiczna gra — oba klienty

- Wejdź do publicznej gry na obu kontach. Powinny trafić do tej samej sesji dla zgodnej kategorii i pojemności. Start po zapełnieniu lobby nie może wysłać `leaveSession` ani wyeliminować gracza.
- Wyślij poprawne i błędne odpowiedzi, także szybkie podwójne kliknięcie. Wybór blokuje się od pierwszego kliknięcia; poprawność pokazuje dopiero serwer. Licznik i wynik nie mogą naliczyć jednej odpowiedzi dwukrotnie.
- Zostaw jedno urządzenie bez odpowiedzi. Po serwerowym deadline runda powinna zostać rozstrzygnięta, a przejście do kolejnej rundy nastąpić bez dodatkowego zapisu klienta. Dla sprawdzenia następnego pytania wybierz wariant, w którym obaj gracze przetrwają rundę, np. obaj odpowiedzą poprawnie. Sprawdź również ścieżkę błędów/losowania i zakończenia przez eliminację.
- Wyłącz sieć podczas wysyłania odpowiedzi i ponownie ją włącz, gdy proces aplikacji nadal działa. Przy utraconej odpowiedzi sieciowej akcja „Ponów” musi wysłać ten sam wybór. Spóźniony błąd poprzedniej rundy nie może zablokować nowego pytania. Jeżeli stream zgłasza błąd, sprawdź „Ponów” dla połączenia.
- Opuść grę świadomie na jednym kliencie. Drugi powinien zobaczyć konsekwencję wyjścia i prawidłowy wynik. Samo chwilowe wyłączenie sieci nie jest świadomym opuszczeniem — obowiązują deadline'y.
- Po `finished/resultsReady` oba konta powinny zobaczyć zgodne wyniki, właściwe miejsca, oznaczenie „Ty” i koronę zwycięzcy. Sprawdź archiwum oraz brak podwójnego naliczenia statystyk. Zmiany rankingu dotyczą wyłącznie sesji oznaczonych na serwerze jako rankingowe; UI nie ma ukończonego przepływu rankingu.

## Prywatna gra — gospodarz i gość

- Utwórz lobby, dołącz z drugiego konta kodem. Błędny kod nie powinien dołączyć gracza. Sprawdź listy graczy i ustawienia na obu urządzeniach.
- Zmień ustawienia gospodarza i zapisz. Gość powinien otrzymać aktualizację, ale nie może sam zapisać ustawień ani uruchomić gry. Uruchom grę dopiero z dwoma uczestnikami i odpowiednią pulą pytań dla ustawień.
- Powtórz odpowiedzi, timeout, chwilową utratę sieci i zakończenie opisane dla gry publicznej. Sprawdź przejście lobby → gra bez komendy opuszczenia.
- W osobnych próbach opuść oczekujące lobby jako gość oraz jako gospodarz. Zweryfikuj usunięcie członkostwa gościa i zamknięcie lobby po wyjściu gospodarza. Nie powinien pozostać pokój, do którego kod pozwala dołączyć mimo zamknięcia.

## Wznowienie i archiwum

- Osobno sprawdź odtworzenie połączenia w nadal otwartym ekranie i pełne zamknięcie/restart aplikacji. Obecny klient nie ma wyszukania aktywnej sesji i automatycznej nawigacji do niej po restarcie. Zapisz to jako ograniczenie; ponowne wejście do matchmakingu nie jest wznowieniem poprzedniej gry.
- Po cleanupie sprawdź odczyt własnego `sessions_archive/{sessionId}` i fallback repozytorium przy braku dokumentu live. UI nie oferuje osobnej przeglądarki historii ani otwierania sesji po ID — ten wariant wymaga narzędzia testowego lub kontrolowanego wywołania repozytorium jako uczestnik. Wynik nie może wymagać istniejącego dokumentu live.
- Uczestnik, który świadomie wyszedł, zachowuje dostęp do archiwum przez `participantUids`. Konto obce nie może odczytać archiwum ani prywatnej sesji. Klient nie może zapisywać statystyk, archiwów ani kluczy odpowiedzi.

## Rzeczywiste Cloud Tasks — osobna próba chmurowa

Sam poprawny wynik na telefonach nie dowodzi działania wszystkich ponowień. W środowisku testowym sprawdź logi funkcji i kolejki w regionie `europe-central2`:

- `roundTimeoutQueue`: zadanie dla właściwego `sessionId`, `roundIndex` i `deadlineMs`; bez aktywności klientów rozstrzyga rundę po zapisanym deadline.
- `roundAdvanceQueue`: przejście dopiero po `resolveAt`; stare lub powtórzone zadanie nie przesuwa nowszej rundy.
- `sessionCleanupQueue`: po potwierdzonym archiwum usuwa dane robocze, zachowując archiwum i statystyki.
- Sprawdź uprawnienia rzeczywistego konta wykonawczego do enqueue oraz wywołania handlerów. W logach odnotuj udane zlecenie i dostarczenie, a nie wyłącznie obecność funkcji we wdrożeniu.
- W kontrolowanej próbie na środowisku testowym doprowadź do przejściowego niepowodzenia handlera/zlecenia i zapisz dowód ponowienia oraz końcowego sukcesu. Nie zmieniaj uprawnień ani nie wywołuj awarii na projekcie używanym przez innych graczy. Powtórzenie finalizacji nie może ponownie zwiększyć statystyk.
- Skonfrontuj konfigurację z kodem: maksymalnie 100 prób, wiek ponowień 86400 s, backoff 1–60 s, do 20 równoległych wywołań. Brak podwójnego enqueue jest kontrolowany deterministycznym ID, ale tylko błąd `functions/task-already-exists` jest ignorowany.

Nie wykonano tej próby ani nie wdrożono zmian w ramach refaktoru. Jeśli nie zostanie wykonana razem z próbami urządzeń, pozostaje otwartym warunkiem przed wdrożeniem.

## Starsze dane i zgodność klientów — do rozstrzygnięcia przed przełączeniem

- Nie mieszać starych klientów/handlerów z nowymi regułami i protokołem. Proponowany wariant to uzgodnione okno zmiany bez aktywnych sesji ze starego schematu, po kopii danych i próbie na środowisku testowym. Właściciel musi zaakceptować sposób przełączenia; klient nie ma mechanizmu wymuszającego aktualizację.
- Starsze archiwa mogą wymagać zaufanego uzupełnienia historycznych `participantUids`. Wznowienie snapshotu z archiwum wymaga `questionIds` i potwierdzonego `statsApplied`; nie dopisywać tego znacznika bez ustalenia, czy statystyki już naliczono. Nie wykonano migracji historycznych archiwów.
- Bank `questions` wymaga rozdzielenia na `public_questions` i `answer_keys` według instrukcji etapu 4. Nie nadpisywać całego korzenia RTDB plikiem zawierającym tylko te drzewa.
- Retencja sesji singleplayer, obsługa wyczerpanych ponowień i zastane podatności npm pozostają ograniczeniami opisanymi w etapach 4–5. Refaktor nie rozstrzyga ich przez automatyczny deploy lub aktualizację zależności.

Etap 8 można uznać za w pełni zweryfikowany dopiero po zapisaniu wyników prób, sukcesie workflow CI oraz decyzjach o przełączeniu i starszych danych. Lokalnie zielone testy nie zamykają tych punktów.
