# Przypadki użycia – Trivia App

Główni aktorzy:
- Użytkownik niezalogowany (Gość)
- Użytkownik zalogowany

---

## PU1: Rejestracja nowego użytkownika

**Nazwa:** Rejestracja nowego użytkownika  

**Aktorzy:**  
- Główny: Użytkownik niezalogowany (Gość) 

**Warunki początkowe:**  
- Użytkownik nie jest zalogowany.  
- Użytkownik posiada dostęp do ekranu startowego aplikacji.

**Warunki końcowe (sukces):**  
- Konto użytkownika zostaje utworzone w systemie.  
- Użytkownik jest zalogowany i przeniesiony do ekranu głównego aplikacji.  

**Warunki końcowe (porażka):**  
- Konto nie zostaje utworzone, użytkownik pozostaje niezalogowany, system prezentuje komunikat błędu.

**Scenariusz:**  
1. Gość wybiera opcję „Zarejestruj się”.  
2. System wyświetla formularz rejestracji (np. e‑mail/ nazwa użytkownika, hasło, potwierdzenie hasła).  
3. Gość wprowadza wymagane dane i zatwierdza formularz.  
4. System weryfikuje poprawność danych (format e‑mail, siła hasła, unikalność konta).  
5. System tworzy konto użytkownika.  
6. System automatycznie loguje nowego użytkownika.  
7. System wyświetla ekran główny aplikacji.

**Scenariusz alternatywny A1 – niepoprawne dane:**  
3a. Gość podaje niepoprawne lub niekompletne dane.  
4a. System wykrywa błąd (np. e‑mail już istnieje, za słabe hasło) i wyświetla odpowiedni komunikat.  
5a. Gość poprawia dane i ponownie zatwierdza formularz (powrót do kroku 3).

**Odnośnik do wymagań:**  
- [F-01] Jako użytkownik chcę mieć możliwość zarejestrować konto, aby zapisywać swoje wyniki.
  

**Odnośnik do innych scenariuszy:**  
- PU2: Logowanie użytkownika

---

## PU2: Logowanie użytkownika

**Nazwa:** Logowanie użytkownika  

**Aktorzy:**  
- Główny: Użytkownik (posiadający konto) 

**Warunki początkowe:**  
- Użytkownik posiada zarejestrowane konto.  
- Użytkownik jest niezalogowany.

**Warunki końcowe (sukces):**  
- Użytkownik jest zalogowany i widzi ekran główny.  

**Warunki końcowe (porażka):**  
- Użytkownik pozostaje niezalogowany, otrzymuje komunikat o błędnych danych.

**Scenariusz:**  
1. Użytkownik wybiera opcję „Zaloguj”.  
2. System wyświetla formularz logowania (e‑mail / nazwa użytkownika + hasło).  
3. Użytkownik podaje dane i zatwierdza logowanie.  
4. System weryfikuje dane logowania.  
5. System loguje użytkownika.  
6. System wyświetla ekran główny aplikacji.

**Scenariusz alternatywny A1 – niepoprawne dane logowania:**  
4a. System odrzuca logowanie z powodu błędnych danych.  
5a. System wyświetla komunikat o błędzie i umożliwia ponowną próbę (powrót do kroku 3).


**Odnośnik do innych scenariuszy:**  
- PU1: Rejestracja nowego użytkownika  

---

## PU3: Wybór trybu gry i quizu

**Nazwa:** Wybór trybu gry i quizu przez użytkownika  

**Aktorzy:**  
- Główny: Użytkownik zalogowany lub niezalogowany

**Warunki początkowe:**  
- Użytkownik ma dostęp do ekranu głównego aplikacji.  
- W systemie dostępne są co najmniej jedne **quizy** i kategorie. [web:9]

**Warunki końcowe (sukces):**  
- Użytkownik ma uruchomiony wybrany quiz i widzi pierwsze pytanie.

**Warunki końcowe (porażka):**  
- Użytkownik nie uruchamia żadnego quizu.

**Scenariusz (główny przepływ):**  
1. Użytkownik otwiera ekran główny.  
2. System prezentuje listę dostępnych trybów gry. 
3. System prezentuje listę dostępnych quizów.  
4. Użytkownik wybiera konkretny quiz.  
5. System pobiera zestaw pytań i przygotowuje sesję quizu.  
6. System wyświetla ekran startowy quizu (opis, zasady, limit czasu itp.).  
7. Użytkownik uruchamia quiz (przycisk „Start”).  
8. System wyświetla pierwsze pytanie (przejście do PU4: Rozwiązywanie quizu).

**Scenariusz alternatywny A1 – zmiana trybu gry:**  
3a. Użytkownik rezygnuje z wyboru quizu.  
4a. System powraca do ekranu głównego (1).

**Scenariusz alternatywny A2 – zmiana quizu:**  
7a. Użytkownik rezygnuje z wybranego quizu.  
8a. System powraca do ekranu wyboru quizu (3).

**Odnośniki do wymagań:**  
- [F-02] Jako użytkownik chcę korzystać z trybu singleplayer bez dostępu do internetu, aby móc grać gdziekolwiek jestem.  
- [F-05] Jako użytkownik chcę mieć wybór poziomu trudności, aby dostosować poziom pytań do moich preferencji.

**Odnośniki do innych scenariuszy:**  
- PU4: Rozwiązywanie quizu

---

## PU4: Rozwiązywanie quizu

**Nazwa:** Rozwiązywanie quizu

**Aktorzy:**  
- Główny: Użytkownik zalogowany lub niezalogowany

**Warunki początkowe:**  
- Użytkownik wybrał konkretny quiz (PU3).  
- System przygotował listę pytań.  
- Quiz jest aktywny; jeśli włączono limit czasu, zegar jest gotowy do uruchomienia. [web:5][web:9]

**Warunki końcowe (sukces):**  
- Użytkownik odpowiedział na wszystkie pytania lub zakończył quiz.  
- Został obliczony wynik i zapis podejścia (dla użytkownika zalogowanego).

**Warunki końcowe (porażka / przerwanie):**  
- Użytkownik opuścił quiz przed końcem (np. zamknięcie aplikacji, rezygnacja) – wynik i zapis podejścia zostały zapisane lub porzucone (zależnie od trybu).

**Scenariusz (główny przepływ):**  
1. System wyświetla pierwsze pytanie quizu (wraz z ewentualnymi odpowiedziami). [web:9]  
2. Jeśli quiz jest limitowany czasowo, system uruchamia odliczanie. [web:5]  
3. Użytkownik wybiera odpowiedź.  
4. System zapisuje odpowiedź użytkownika dla bieżącego pytania i wyświetla poprawną odpowiedź.  
5. System przechodzi do następnego pytania.  
6. Kroki 1–5 powtarzane są, aż do wyczerpania pytań lub upływu limitu czasu.  
7. Po zakończeniu quizu system oblicza wynik użytkownika. [web:9][web:12]  
8. System zapisuje podejście do quizu w historii użytkownika (jeśli jest zalogowany). [web:9]  
9. System wyświetla ekran wyników (PU5: Wyświetlenie wyników quizu).

**Scenariusz alternatywny A1 – koniec czasu:**  
2a. Limit czasu dla aktualnego pytania / całego quizu upływa. [web:5]  
3a. System traktuje nieodpowiedziane pytania jako błędne.
4a. System przechodzi do kroku 7.

**Scenariusz alternatywny A2 – wcześniejsze zakończenie:**  
3b. Użytkownik wybiera opcję „Zakończ quiz” przed odpowiedzią na wszystkie pytania.  
4b. System prosi o potwierdzenie.  
5b. Po potwierdzeniu system kończy quiz i przechodzi do kroku 7.

**Odnośniki do wymagań:**  
- [F-03] Jako użytkownik chcę widzieć wyniki i poprawne odpowiedzi po każdej rundzie, aby się uczyć.

**Odnośniki do innych scenariuszy:**  
- PU3: Wybór quizu  
- PU5: Wyświetlenie wyników quizu  

---

## PU5: Wyświetlenie wyników quizu i szczegółów

**Nazwa:** Wyświetlenie wyników quizu  

**Aktorzy:**  
- Główny: Użytkownik zalogowany lub niezalogowany

**Warunki początkowe:**  
- Quiz został zakończony (PU4).  
- System obliczył wynik.

**Warunki końcowe (sukces):**  
- Użytkownik widzi swój wynik, może przeanalizować odpowiedzi i przejść dalej (np. do kolejnego quizu lub historii). [web:9][web:12]

**Scenariusz:**  
1. System wyświetla ekran wyników zawierający:  
   - Łączną liczbę punktów / poprawnych odpowiedzi  
   - Procent poprawnych odpowiedzi  
   - Czas trwania podejścia
   - Zdobyte miejsce (tryb rankingowy) [web:9][web:12]  
2. System przedstawia informację, czy użytkownik poprawił swój najlepszy wynik (dla zalogowanych).  
3. System daje możliwość wyświetlenia szczegółów odpowiedzi (np. pełna lista pytań z zaznaczeniem odpowiedzi poprawnych i udzielonych). [web:9]  
4. Użytkownik może:  
   - Powrócić do ekranu głównego  
   - Rozwiązać ten sam quiz ponownie

**Odnośniki do innych scenariuszy:**  
- PU4: Rozwiązywanie quizu  
- PU6: Przegląd historii quizów  

---

## PU6: Przegląd historii quizów użytkownika

**Nazwa:** Przegląd historii podejść do quizów  

**Aktorzy:**  
- Główny: Użytkownik zalogowany  

**Warunki początkowe:**  
- Użytkownik jest zalogowany.  

**Warunki końcowe:**  
- Użytkownik przegląda historię i może wybrać konkretne podejście do analizy.

**Scenariusz:**  
1. Użytkownik wybiera opcję „Historia quizów”.  
2. System pobiera i wyświetla listę wcześniejszych podejść (quiz, data, wynik, czas trwania). [web:9]  
3. Użytkownik wybiera konkretne podejście.  
4. System wyświetla szczegóły wyniku (np. pytania, odpowiedzi poprawne i błędne). [web:9]  
5. Użytkownik może zdecydować o ponownym rozwiązaniu danego quizu (przejście do PU3 / PU4).

**Scenariusz alternatywny A1 – brak historii:**  
2a. Jeśli użytkownik nie rozwiązał jeszcze żadnych quizów, system wyświetla informację o braku historii.

**Odnośniki do wymagań:**  
- [F-09] Jako użytkownik chcę otrzymywać odznaki za osiągnięcia oraz sprawdzać historię quizów, aby czuć postęp.
- [F-11] Jako użytkownik chcę mieć możliwość śledzenia postępu i statystyk innych graczy, aby móc porównać się z nimi.

**Odnośniki do innych scenariuszy:**  
- PU3: Wybór quizu  
- PU5: Wyświetlenie wyników quizu  
