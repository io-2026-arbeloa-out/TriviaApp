```mermaid
flowchart LR
    subgraph Actors[ ]
        A1([Użytkownik<br/>zalogowany])
        A2([Użytkownik<br/>niezalogowany])
    end
    subgraph System[Trivia App]
        direction TB
        PU1((PU1:<br/>Rejestracja))
        PU2((PU2:<br/>Logowanie))
        PU3((PU3:<br/>Wybór trybu i quizu))
        PU4((PU4:<br/>Rozwiązywanie quizu))
        PU5((PU5:<br/>Wyświetlenie wyników))
        PU6((PU6:<br/>Historia quizów))
    end
    A2 --> |Zaloguj| PU2
    A1 --> PU3
    A2 --> |Zarejestruj| PU1
    A2 --> PU3
    PU1 --> |Rejestracja zakończona sukcesem| PU2
    PU2 --> |Logowanie zakończone sukcesem| A1
    PU3 --> |Rozpocznij quiz| PU4
    PU4 --> PU5
    A1 --> |Profil -> Historia gier| PU6
    PU6 --> |Wybranie jednego z quizów -> Rozwiąż ponownie| PU4
    PU5 --> |Wróć do menu głównego| PU3
    PU5 --> |Rozpocznij ponownie quiz| PU4
    PU4 --> |Wyjdź z gry| PU3
```