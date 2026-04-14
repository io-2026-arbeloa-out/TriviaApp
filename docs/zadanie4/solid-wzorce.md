# Zasady SOLID i wzorce projektowe w architekturze aplikacji quizowej

## Zasady SOLID

### Single Responsibility Principle (SRP) – Zasada jednej odpowiedzialności

Każda klasa ma jedną, jasno zdefiniowaną odpowiedzialność, co ogranicza jej zakres i upraszcza modyfikacje.

Przykłady zastosowania:

* Ekrany UI (`LoginScreen`, `ProfileScreen`, `LeaderboardScreen`) odpowiadają wyłącznie za prezentację konkretnego widoku i obsługę interakcji użytkownika.
* Serwisy autoryzacji są rozdzielone na `AuthLoginService` i `AuthRegisterService`, dzięki czemu logika logowania jest niezależna od logiki rejestracji.
* Serwisy gier (`SingleplayerGameService`, `MultiplayerGameService`, `PrivateGameCreationService`, `PrivateGameJoinService`) obsługują pojedynczy tryb lub pojedynczy typ operacji (tworzenie vs dołączanie do gry).
* Repozytoria (`FirebaseAuthRepository`, `FirebaseQuestionRepository`, `FirebaseProfileRepository`) zarządzają dostępem do jednego, konkretnego typu danych.
* Modele danych (`Question`, `Player`, `SessionData`, `ProfileData`) reprezentują pojedyncze encje domenowe.

Dzięki SRP zmiana jednego fragmentu logiki (np. rejestracji) nie wymusza modyfikacji innych obszarów (np. logowania lub rozgrywki), co poprawia czytelność i testowalność kodu.

\---

### Open/Closed Principle (OCP) – Zasada otwarte/zamknięte

Moduły są otwarte na rozszerzenia, ale zamknięte na modyfikacje dzięki wykorzystaniu interfejsów jako abstrakcji.

Schemat zależności:

```text
Ekran (UI)  →  Interfejs (abstrakcja)  ←  Serwis (implementacja)  →  Repozytorium
```

Przykłady rozszerzeń bez ruszania istniejącego kodu:

* Dodanie logowania przez Google polega na stworzeniu `GoogleAuthLoginService` implementującego `ILoginAuthService`, bez zmian w ekranach lub istniejących serwisach.
* Zmiana backendu z Firebase na inny (np. Supabase) sprowadza się do dodania nowych repozytoriów (np. `SupabaseQuestionRepository`) i podmiany implementacji w warstwie DI.
* Nowy tryb gry (np. tryb turniejowy) można dodać jako nowy interfejs i nową implementację serwisu, bez ingerencji w istniejące tryby.

OCP sprawia, że rozwój systemu polega na dopisywaniu nowych klas zamiast ciągłego modyfikowania istniejących, co ogranicza ryzyko regresji.

\---

### Liskov Substitution Principle (LSP) – Zasada podstawienia Liskov

Każdą implementację interfejsu można bezpiecznie podstawiać w miejsce tego interfejsu, nie łamiąc oczekiwań klienta.

Przykładowe interfejsy i implementacje:

```text
AuthLoginService        ..|> ILoginAuthService
AuthRegisterService     ..|> IRegisterAuthService
SingleplayerGameService ..|> ISingleplayerGameService
MultiplayerGameService  ..|> IMultiplayerGameService
LeaderboardService      ..|> ILeaderboardService
```

Ekrany UI korzystają wyłącznie z typów interfejsowych, np.:

```dart
class LoginScreen {
  ILoginAuthService \\\\\\\_authService; // może to być AuthLoginService, MockAuthService, GoogleAuthLoginService...
}
```

Dzięki temu:

* W testach można wstrzyknąć mocki (`MockLoginAuthService`) bez zmiany kodu ekranu.
* Każda implementacja interfejsu musi spełniać ten sam kontrakt (sygnatury metod i typy zwracane).
* Podstawienie innej implementacji nie zmienia poprawnego działania klienta.

\---

### Interface Segregation Principle (ISP) – Zasada segregacji interfejsów

Interfejsy są małe, wyspecjalizowane i projektowane tak, aby klienci nie byli zmuszani do zależności od metod, których nie używają.

Przykłady segregacji:

* **Autoryzacja**:

```text
ILoginAuthService    → signInWithEmail(), signOut(), authStateChanges()
IRegisterAuthService → register(), generateProfile(), authStateChanges()
```

`LoginScreen` korzysta tylko z `ILoginAuthService` i nie musi znać metody `register()`.

* **Gry prywatne**:

```text
IPrivateGameCreationService → createPrivateGame(), deleteGame()
IPrivateGameJoinService     → joinPrivateGame(), leaveGame(), listenToLobby()
```

Ekran tworzenia gry używa tylko operacji tworzenia i usuwania, a ekran dołączania – wyłącznie metod dołączania i nasłuchiwania lobby.

* **Opcje**:

```text
IGameOptionsService → saveOptions(), getOptions()
IUserOptionsService → saveOptions(), getOptions()
IUIOptionsService   → loadUIOptions(), saveUIOptions()
```

Każdy ekran otrzymuje minimalny, dopasowany do siebie interfejs. Dzięki ISP eliminujemy “grube” interfejsy i zbędne zależności.

\---

### Dependency Inversion Principle (DIP) – Zasada odwrócenia zależności

Warstwa wysokopoziomowa (UI) i niskopoziomowa (serwisy, repozytoria) zależą od abstrakcji, a nie od siebie nawzajem.

Struktura warstw:

```text
┌─────────────────┐
│   UI (Ekrany)   │  ← zależy od interfejsów
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Interfejsy    │  ← ILoginAuthService, IMultiplayerGameService, ...
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Serwisy      │  ← AuthLoginService, MultiplayerGameService, ...
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Repozytoria    │  ← FirebaseAuthRepository, FirebaseSessionRepository, ...
└─────────────────┘
```

Przykłady zależności:

* `LoginScreen` zależy od `ILoginAuthService`, a nie od konkretnego `AuthLoginService`.
* `ProfileScreen` korzysta z `IProfileDataService`, a nie sztywno z `ProfileDataService`.
* `MultiplayerGameScreen` używa `IMultiplayerGameService`, nie znając konkretnej implementacji.

DIP umożliwia swobodną podmianę szczegółów implementacyjnych (np. typu repozytoriów lub backendu) bez naruszania logiki aplikacji.

\---

## Wzorce projektowe

## Wzorzec Obserwatora (Observer Pattern)

Zastosowanie: metody zwracające `Stream` w interfejsach serwisów i repozytoriach, np.:

* `ILoginAuthService`: `Stream authStateChanges()`
* `IMultiplayerGameService`: `Stream<SessionData> listenToSession(String sessionId)`
* `IPrivateGameJoinService`: `Stream<SessionData> listenToLobby(String sessionId)`
* `FirebaseSessionRepository`: `Stream getSessionStream(String sessionId)`

Komponenty subskrybują strumienie i są automatycznie powiadamiane o zmianach stanu – np. o wejściu nowego gracza do lobby, zmianie statusu sesji czy zmianie stanu autoryzacji.

Korzyści:

* Obsługa komunikacji w czasie rzeczywistym, kluczowej dla trybu multiplayer.
* Naturalna integracja z reaktywnym UI w Flutterze (`StreamBuilder`).
* Odsprzęglenie producentów zdarzeń (repozytoria) od ich konsumentów (serwisy, ekrany).

\---

### Wzorzec Strategii (Strategy Pattern)

Zastosowanie: różne implementacje logiki gry ukryte za wspólnymi interfejsami:

```text
ISingleplayerGameService  ←  SingleplayerGameService
IMultiplayerGameService   ←  MultiplayerGameService
```

Obie implementacje udostępniają podobny zestaw operacji (np. `checkAnswer()`, `registerAnswer()`, `endGame()`), ale różnią się wewnętrzną logiką:

* Singleplayer:

  * Sesja lokalna.
  * Odpowiedzi rejestrowane tylko dla jednego gracza.
  * Brak synchronizacji między klientami.
* Multiplayer:

  * Sesja współdzielona w Firebase.
  * Konieczność identyfikacji graczy (`Player`).
  * Synchronizacja i propagacja zmian w czasie rzeczywistym.

Dzięki temu ekrany mogą korzystać z odpowiedniej strategii gry bez znajomości szczegółów implementacji, a dodanie nowego trybu (np. treningowego czy turniejowego) wymaga jedynie nowej implementacji interfejsu.

\---

### Wzorzec Fasady (Facade Pattern)

Zastosowanie: serwisy pełnią rolę fasad upraszczających złożone operacje, np.:

```text
SingleplayerGameService
  ├── FirebaseSessionRepository
  └── FirebaseQuestionRepository

LeaderboardService
  ├── FirebaseLeaderboardRepository
  └── FirebaseProfileRepository

AuthRegisterService
  ├── FirebaseAuthRepository
  └── FirebaseProfileRepository
```

Serwisy ukrywają złożoność koordynacji wielu repozytoriów za prostym interfejsem.

Przykłady:

* `RegistrationScreen` wywołuje pojedynczą metodę `register()`, która pod spodem tworzy konto w Firebase Auth i dokument profilu w Firestore.
* `SingleplayerGameService.startGame()` pobiera pytania i zakłada sesję gry jako jedną, spójną operację.

Dzięki fasadzie warstwa UI jest prostsza, a złożoność pozostaje w serwisach.

