# Etap 5 — trwałe rundy i finalizacja

Zmiany przygotowane do review 20.10.2026. Nie wykonano wdrożenia, migracji danych ani commita.

## Przebieg gry

1. Start prywatnej gry lub automatyczny start publicznej gry zapisuje `roundStartedAt`, `roundDeadline` i licznik z `eligibleUids` w tej samej transakcji. Deadline wynika z `questionTimeLimit` (10/20/30/60 sekund). Komenda odpowiedzi odrzuca nowy wybór po deadline; identyczne ponowienie wcześniej przyjętej odpowiedzi nadal zwraca jej wynik.
2. `resolveRound` czyta sesję, licznik i odpowiedzi wewnątrz transakcji. Rozstrzyga po odpowiedziach wszystkich aktualnie aktywnych graczy, po deadline albo gdy pozostał najwyżej jeden aktywny gracz. Odpowiedzi uczestników, którzy już wyszli, nie zastępują odpowiedzi nadal aktywnych osób.
3. Czysta funkcja `calculateRound` wylicza eliminację i statystyki z przekazanych danych oraz kontrolowanego źródła losowości. Zachowuje dotychczasową loterię z wagą `lotteryTickets + 1` i losowanie po trzech kolejnych rundach bez błędu. Nie zmieniano polityki klasyfikacji miejsc.
4. W jednej transakcji zapisuje się cały rekord rundy (`playerAnswers`, `isCorrect`, wynik losowania i eliminacja), statystyki graczy, `resolved: true` licznika oraz `phase: resolving` z `resolveAt`. Brak odpowiedzi nie daje punktu. Przyjęta odpowiedź osoby, która potem wyszła, pozostaje w historii i jej statystykach; samo wyjście bez odpowiedzi nie dodaje tej osobie próby.
5. `roundAdvanceQueue` przechodzi dalej po pięciu sekundach prezentacji wyniku. Sprawdza numer rundy, fazę i zapisany `resolveAt`. Kolejna runda otrzymuje własny licznik i deadline atomowo. Gdy gra ma się skończyć, zadanie wykonuje finalizację.

Nie ma `setTimeout` ani oczekiwania wewnątrz funkcji na koniec prezentacji. Triggery mają włączone ponowienia i zawsze odczytują aktualny stan, zamiast stosować dane starego eventu. Dotyczy to również pierwszego startu, w którym pole `phase` już wcześniej miało wartość `answering`.

## Zadania i ponowienia

- `roundTimeoutQueue`: timeout według zapisanego deadline.
- `roundAdvanceQueue`: przejście po prezentacji wyniku.
- `sessionCleanupQueue`: usunięcie danych roboczych zakończonej gry.

Zadania mają deterministyczne ID (SHA-256 z typu, sesji, rundy i deadline) oraz bezwzględny czas wykonania. Błąd `functions/task-already-exists` jest traktowany jako potwierdzenie wcześniejszego zlecenia; inne błędy trafiają do mechanizmu ponowień. Stare zadanie nie zmienia nowszej rundy. Zadanie dostarczone przed właściwym terminem zgłasza błąd do ponowienia.

Każdy handler po operacji ponownie uzgadnia zadania z aktualnym stanem. Awaria po zatwierdzeniu transakcji i przed zleceniem następnego zadania nie wymaga odtwarzania wyniku z pamięci procesu. Konfiguracja kolejki: do 100 prób, limit wieku ponowień 86400 sekund, odstęp 1–60 sekund. Nie jest to gwarancja działania podczas nieograniczonej awarii infrastruktury; wyczerpane ponowienia wymagają interwencji operacyjnej.

## Finalizacja i dostęp klienta

Archiwum, `statsApplied: true`, przyrosty statystyk wszystkich graczy i `finished/resultsReady: true` sesji są zapisywane w jednej transakcji. Znacznik rozliczenia znajduje się w archiwum i pozostaje po usunięciu aktywnej sesji. Ponowienie nie nalicza statystyk ponownie. Samo `finished` nie kończy pracy serwera, jeśli nie ma potwierdzenia gotowości wyniku.

Archiwum zawiera wszystkie rundy oraz `questionIds` i historycznych uczestników. Wyjście ostatniego gracza z aktywnej gry nie usuwa sesji — gra przechodzi przez zapis wyniku i finalizację. Opuszczone lobby oczekujące nadal można usunąć bez rozliczania gry.

Cleanup sprawdza gotowość wyniku i znacznik archiwum, usuwa odpowiedzi oraz liczniki partiami do 200 dokumentów, a na końcu dokument sesji. Można go powtarzać po przerwaniu między partiami; archiwum i statystyki pozostają nietknięte.

Klient nie ogłasza końca gry przed `resultsReady`. Jeżeli cleanup usunie sesję przed odczytem lub ponownym połączeniem, repozytorium odtwarza końcowy stan z rozliczonego archiwum. Reguły pozwalają historycznemu uczestnikowi odczytać brak aktywnego dokumentu dla własnego archiwum; obca osoba nie otrzymuje tego uprawnienia.

## Weryfikacja

- `flutter test --no-pub`: 344 testy Fluttera, w tym gotowość wyników, ciągła subskrypcja przez cleanup i inicjalizacja po usunięciu sesji.
- W `functions`: `npm test` sprawdza czystą logikę rundy, klasyfikację i zlecanie zadań (7 testów).
- W `functions`: `npm run test:security` — 40 zaliczonych testów na lokalnych emulatorach Firestore i RTDB w projekcie `demo-triviaapp`. Zestaw obejmuje reguły, komendy gry, pierwsze timeouty dla wszystkich limitów czasu, historię wielu rund, ponowienia, rozliczenie rankingowe i wyścigi odpowiedzi/wyjść.
- Testy przerwań obejmują każdy z czterech zapisów transakcji finalizacji, przerwanie po jej commitcie, przerwanie po commitcie rozstrzygnięcia i przejścia do następnej rundy, błąd zlecenia zadania oraz przerwanie cleanupu między partiami.
- `dart analyze lib test`: zero błędów; pozostało 175 zastanych ostrzeżeń/informacji. Analiza nie jest w całości zielona.

Usunięto stary trigger `onAnswerCreate` i jego nieużywany już walidator. Testy kontraktu kluczy pytań (`01`, `1`, klucz tekstowy), nieprawidłowych danych oraz brakujących/uszkodzonych kluczy odpowiedzi przeniesiono do testów rzeczywistych komend na emulatorach.

Emulatory sprawdzają transakcje i reguły. Zlecanie Cloud Tasks jest testowane z podstawioną kolejką; lokalne testy nie stanowią pełnego testu rzeczywistego transportu Cloud Tasks, uprawnień IAM i automatycznego dostarczania eventów w chmurze.

## Przed wdrożeniem

Wdrożenie wymaga uzgodnionej aktualizacji backendu, reguł Firestore i klienta oraz próby na środowisku testowym z rzeczywistymi kolejkami i triggerami. Dwie nowe funkcje kolejek muszą być dostępne z właściwymi uprawnieniami do zlecania zadań. Stary `onAnswerCreate` należy usunąć z wdrożenia, a istniejący `roundTimeoutQueue` zaktualizować wraz z resztą backendu.

Przed przełączeniem należy zakończyć sesje ze starego schematu: nie mają nowych deadline'ów i `eligibleUids`. Nie można mieszać starych handlerów z nowym przebiegiem rund. Starsze archiwa zachowują dotychczasowy odczyt wyników; wznowienie stanu gry z archiwum wymaga `questionIds` i potwierdzonego `statsApplied`. Znacznika nie wolno dopisywać bez ustalenia, czy statystyki zostały już naliczone. Jeśli istnieje stare częściowo zapisane archiwum bez takiego potwierdzenia, backend zgłasza błąd zamiast ryzykować podwójne naliczenie.

Migracja wspólnego banku pytań i reguł RTDB opisana w `refactor-stage4.md` pozostaje wymagana. Nie zmieniano zależności ani ograniczeń audytu npm opisanych w poprzednim etapie.
