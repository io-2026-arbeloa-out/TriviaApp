```mermaid
classDiagram
direction LR

class Question {
-String \_id
-String \_text
-Set\~String\~ \_correctAnswers
-Set\~String\~ \_wrongAnswers
}

class PrivateGameOptions {
-String \_quizId
-int \_maxPlayers
-int \_entryCode
-int \_questionTimeLimit
-string \_quizCategory
-string \_mode
}

class ProfileData {
-String \_uid
-String \_username
-int \_totalQuestionsAnswered
-int \_correctAnswers
-string \_rank
-int \_ratingPoints
-int \_rankedGamesPlayed
-int \_rankedGamesWon
}

class UIOptions {
-string \_mainColor
-string \_secondaryColor
}

class SessionData {
-String \_sessionId
-int \_numPlayers
-SessionStatus \_status
-DateTime \_startTime
-DateTime \_endTime
-List\~Player\~ \_players
-List\~int\~ \_placement
-List\~Question\~ \_questions
-int \_code
}

class UserOptions {
-int \_soundVolume
-int \_musicVolume
}

class Player {
-String \_uid
-String \_name
}

class LoginData {
-String \_uid
-String \_email
-String \_password
}

class SessionStatus{
~~enumeration~~
-FINISHED
-IN\_PROGRESS
-ABORTED
}

SessionData "1" --o "many" Player : contains
SessionData "1" --o "many" Question : contains
SessionData --> SessionStatus : uses

%% =====================
%% UI – EKRANY
%% =====================

class LoadingScreen {
-Future\~void\~ \_loadAssets()
-void \_navigateToNext()
+Widget build(BuildContext context)
}

class MainMenuScreen {
-void \_onClickSingleplayerGame()
-void \_onClickMultiplayerGame()
-void \_onClickCreatePrivateGame()
-void \_onClickJoinPrivateGame()
+Widget build(BuildContext context)
}

class ProfileScreen {
-IProfileDataService \_profileDataService
-IAchievementService \_achievementService

\-Future\~void\~ \_loadProfile()
-void \_onClickAchievements()
+Widget build(BuildContext context)
}

class QuizListScreen {
-IQuizListService \_quizListService

\-Future\~void\~ \_loadQuizzes()
-void \_onClickQuiz(String quizId)
+Widget build(BuildContext context)
}

class GameOptionsScreen {
-IGameOptionsService \_gameOptionsService

\-Future\~void\~ \_onClickSave()
-void \_onClickClose()
+Widget build(BuildContext context)
}

class UserOptionsScreen {
-IUserOptionsService \_userOptionsService

\-Future\~void\~ \_onClickSave()
-void \_onClickClose()
+Widget build(BuildContext context)
}

class PrivateLobbyScreen {
-IPrivateGameCreationService \_privateGameCreationService
-IPrivateGameJoinService \_privateGameJoinService
-int \_code

\-Future\~void\~ \_onClickCreate()
-Future\~void\~ \_onClickJoin(int \_code)
-void \_onClickLeave()
+Widget build(BuildContext context)
}

class MultiplayerLobbyScreen {
-IMultiplayerConnectionService \_multiplayerConnectionService

\-void \_onClickLeave()
+Widget build(BuildContext context)
}

class SingleplayerGameScreen {
-ISingleplayerGameService \_singleplayerGameService

\-Future\~void\~ \_onStartGame()
-Future\~void\~ \_showQuestion()
-void \_onAnswerSubimtted(string answer)
-Future\~void\~ \_onEndGame()
+Widget build(BuildContext context)
}

class MultiplayerGameScreen {
-IMultiplayerGameService \_multiplayerGameService

\-void \_onAnswerSubimtted(string answer)
-Future\~void\~ \_onEndGame()
+Widget build(BuildContext context)
}

class LeaderboardScreen {
-ILeaderboardService \_leaderboardService

\-Future\~void\~ \_loadLeaderboard()
-void \_onClickClose()
+Widget build(BuildContext context)
}

class ScoreTableScreen {
-IScoreTableService \_scoreTableService

\-void \_onClickPlayAgain()
-void \_onClickMainMenu()
-void \_showTable()
+Widget build(BuildContext context)
}

class LoginScreen {
-ILoginAuthService \_authService
-String \_email
-String \_password

\-Future\~void\~ \_onClickLogin(string \_email, string \_password)
-void \_onClickOpenRegister()
-void \_showMessage()
+Widget build(BuildContext context)
}

class RegistrationScreen {
-IRegisterAuthService \_authService
-String \_email
-String \_password
-String \_username

\-void \_onClickClose()
-Future\~void\~ \_onClickRegister(string email, string password, string username)
-void \_showMessage()
+Widget build(BuildContext context)
}

class AchievementScreen {
-IAchievementService \_achievementService

\-void \_onClickClose()
-Future\~void\~ \_showAchievements()
+Widget build(BuildContext context)
}

%% Ekrany --> Interfejsy serwisów (dependency)
ProfileScreen --> IProfileDataService : uses
ProfileScreen --> IAchievementService : uses
QuizListScreen --> IQuizListService : uses
GameOptionsScreen --> IGameOptionsService : uses
UserOptionsScreen --> IUserOptionsService : uses
PrivateLobbyScreen --> IPrivateGameCreationService : uses
PrivateLobbyScreen --> IPrivateGameJoinService : uses
MultiplayerLobbyScreen --> IMultiplayerConnectionService : uses
SingleplayerGameScreen --> ISingleplayerGameService : uses
MultiplayerGameScreen --> IMultiplayerGameService : uses
LeaderboardScreen --> ILeaderboardService : uses
ScoreTableScreen --> IScoreTableService : uses
LoginScreen --> ILoginAuthService : uses
RegistrationScreen --> IRegisterAuthService : uses
AchievementScreen --> IAchievementService : uses

%% =====================
%% WIDGETY
%% =====================

class BottomNavigationBar {
-int \_currentIndex

\-void \_onClickProfile()
-void \_onClickQuizes()
-void \_onClickMainMenu()
+Widget build(BuildContext context)
}

class LoginRegisterPopUp {
-void \_onClickLogin()
-void \_onClickRegister()
-void \_onClickClose()
-void \_showPopUp()
-void \_closePopUp()
+Widget build(BuildContext context)
}

%% Widgety --> Ekrany (nawigacja)
BottomNavigationBar --> ProfileScreen : navigates to
BottomNavigationBar --> QuizListScreen : navigates to
BottomNavigationBar --> MainMenuScreen : navigates to
LoginRegisterPopUp --> LoginScreen : opens
LoginRegisterPopUp --> RegistrationScreen : opens
MainMenuScreen --> SingleplayerGameScreen : navigates to
MainMenuScreen --> MultiplayerLobbyScreen : navigates to
MainMenuScreen --> PrivateLobbyScreen : navigates to
ProfileScreen --> AchievementScreen : navigates to
LoadingScreen --> MainMenuScreen : navigates to

%% =====================
%% INTERFEJSY SERWISÓW
%% =====================

class ILoginAuthService {
~~interface~~
+Future\~void\~ signInWithEmail(String email, String password)
+Future\~void\~ signOut()
+Stream authStateChanges()
}

class IRegisterAuthService {
~~interface~~
+Future\~void\~ register(String email, String password, String displayName)
+Future\~ProfileData\~ generateProfile()
+Stream authStateChanges()
}

class IQuestionService {
~~interface~~
+Future\~List\~Question\~\~ getQuestions(int limit, int categoryID)
}

class ISingleplayerGameService {
~~interface~~
+Future\~SessionData\~ startGame(GameOptions options)
+Future\~void\~ registerAnswer(Question question, String answer)
+bool checkAnswer(Question question, String answer)
+Future\~void\~ endGame(SessionData session)
}

class IMultiplayerConnectionService {
~~interface~~
+void connectPlayer()
+Future\~void\~ connectPlayers()
+Future\~void\~ startMultiplayerGame()
}

class IMultiplayerGameService {
~~interface~~
+Future\~void\~ registerAnswer(Player player, Question question, String answer)
+bool checkAnswer(Question question, String answer)
+Future\~void\~ endGame(SessionData session)
+Stream\~SessionData\~ listenToSession(String sessionId)
}

class IPrivateGameCreationService {
~~interface~~
+Future\~SessionData\~ createPrivateGame(GameOptions options)
+Future\~void\~ deleteGame(String sessionId)
+Future\~void\~ startGame(String sessionId)
}

class IPrivateGameJoinService {
~~interface~~
+Future\~SessionData\~ joinPrivateGame(int code)
+Future\~void\~ leaveGame(String sessionId, String playerId)
+Stream\~SessionData\~ listenToLobby(String sessionId)
+void ready()
}

class IGameOptionsService {
~~interface~~
+Future\~void\~ saveOptions(PrivateGameOptions options)
+Future\~PrivateGameOptions\~ getOptions()
}

class IUserOptionsService {
~~interface~~
+Future\~void\~ saveOptions(UserOptions options)
+Future\~UserOptions\~ getOptions()
}

class IUIOptionsService {
~~interface~~
+Future\~UIOptions\~ getUIOptions()
+Future\~void\~ saveUIOptions(UIOptions options)
}

class ILeaderboardService {
~~interface~~
+Future\~List\~ProfileData\~\~ getLeaderboard()
+Future\~int\~ getUserRank(String uid)
}

class IAchievementService {
~~interface~~
+Future\~List\~Achievement\~\~ getAchievements(ProfileData profile)
+Future\~void\~ updateAchievements(ProfileData profile)
}

class IQuizListService {
~~interface~~
+Future\~List\~Quiz\~\~ getQuizList()
}

class IProfileDataService {
~~interface~~
+Future\~ProfileData\~ getProfileData(String uid)
+Future\~void\~ updateProfileData(ProfileData data)
}

class IScoreTableService {
~~interface~~
+Future\~SessionData\~ getGameData(String sessionid)
}

%% =====================
%% SERWISY
%% =====================

class AppRoute {
-String \_route

\-void GoToProfile()
-void GoToCategories()
-void GoToMainMenu()
-void GoToLeaderboard()
-void GoToAchievements()
-void GoBack()
}

class AuthLoginService {
-FirebaseAuthRepository \_authRepository

\-Future\~void\~ \_signInWithEmail(String email, String password)
-Future\~void\~ \_signOut()
-Stream \_authStateChanges()
}

class AuthRegisterService {
-FirebaseAuthRepository \_authRepository
-FirebaseProfileRepository \_profileRepository

\-Future\~void\~ \_register(String email, String password, String username)
-Future\~ProfileData\~ \_generateProfile()
-Stream \_authStateChanges()
}

class QuestionService {
-FirebaseQuestionRepository \_questionRepository

\-Future\~List\~Question\~\~ \_getQuestions(int limit, string category)
}

class SingleplayerGameService {
-FirebaseSessionRepository \_sessionRepository
-FirebaseQuestionRepository \_questionRepository

\-Future\~SessionData\~ \_startGame(GameOptions options)
-Future\~void\~ \_registerAnswer(Question question, String answer)
-bool \_checkAnswer(Question question, String answer)
-Future\~void\~ \_endGame(SessionData session)
}

class MultiplayerConnectionService {
+void connectPlayer()
+Future\~void\~ connectPlayers()
+Future\~void\~ startMultiplayerGame()
}

class MultiplayerGameService {
-FirebaseSessionRepository \_sessionRepository
-FirebaseQuestionRepository \_questionRepository



\-Future\~void\~ \_startMultiplayerGame()
-Future\~void\~ \_registerAnswer(Player player, Question question, String answer)
-bool \_checkAnswer(Question question, String answer)
-Future\~void\~ \_endGame(SessionData session)
-Stream\~SessionData\~ \_listenToSession(String sessionId)
}

class PrivateGameCreationService {
-FirebaseSessionRepository \_sessionRepository

\-Future\~SessionData\~ \_createPrivateGame(GameOptions options)
-Future\~void\~ \_deleteGame(String sessionId)
}

class PrivateGameJoinService {
-FirebaseSessionRepository \_sessionRepository

\-Future\~SessionData\~ \_joinPrivateGame(int code)
-Future\~void\~ \_leaveGame(String sessionId, String playerId)
-Stream\~SessionData\~ \_listenToLobby(String sessionId)
}

class GameOptionsService {
-FirebaseOptionsRepository \_optionsRepository

\-Future\~void\~ \_saveOptions(UserOptions options)
-Future\~UserOptions\~ \_getOptions()
}

class UserOptionsService {
-FirebaseOptionsRepository \_optionsRepository

\-Future\~void\~ \_saveOptions(UserOptions options)
-Future\~UserOptions\~ \_getOptions()
}

class UIOptionsService {
-FirebaseOptionsRepository \_optionsRepository

\-Future\~UIOptions\~ \_loadUIOptions()
-Future\~void\~ \_saveUIOptions(UIOptions options)
}

class LeaderboardService {
-FirebaseLeaderboardRepository \_leaderboardRepository
-FirebaseProfileRepository \_profileRepository

\-Future\~List\~ProfileData\~\~ \_getLeaderboard()
-Future\~int\~ \_getUserRank(String userId)
}

class AchievementService {
-FirebaseAchievementRepository \_achievementRepository

\-Future\~List\~Achievement\~\~ \_getAchievements(ProfileData profile)
-Future\~void\~ \_updateAchievements(ProfileData profile, SessionData result)
}

class QuizListService {
-FirebaseQuizRepository \_quizRepository

\-Future\~List\~Quiz\~\~ \_getQuizList()
}

class ProfileDataService {
-FirebaseProfileRepository \_profileRepository

\-Future\~ProfileData\~ \_getProfileData(String uid)
-Future\~void\~ \_updateProfileData(ProfileData data)
}

class ScoreTableService {
-FirebaseSessionRepository \_sessionRepository

\-Future\~SessionData\~ \_getGameData(String sessionid)
}

%% Serwisy implementują interfejsy
AuthLoginService ..|> ILoginAuthService : implements
AuthRegisterService ..|> IRegisterAuthService : implements
QuestionService ..|> IQuestionService : implements
SingleplayerGameService ..|> ISingleplayerGameService : implements
MultiplayerConnectionService ..|> IMultiplayerConnectionService : implements
MultiplayerGameService ..|> IMultiplayerGameService : implements
PrivateGameCreationService ..|> IPrivateGameCreationService : implements
PrivateGameJoinService ..|> IPrivateGameJoinService : implements
GameOptionsService ..|> IGameOptionsService : implements
UserOptionsService ..|> IUserOptionsService : implements
UIOptionsService ..|> IUIOptionsService : implements
LeaderboardService ..|> ILeaderboardService : implements
AchievementService ..|> IAchievementService : implements
QuizListService ..|> IQuizListService : implements
ProfileDataService ..|> IProfileDataService : implements
ScoreTableService ..|> IScoreTableService : implements

%% =====================
%% FIREBASE / INFRASTRUKTURA
%% =====================

class FirebaseAuthRepository {
-Future\~ProfileData\~ registerWithEmail(String email, String password, String displayName)
-Future\~ProfileData\~ signInWithEmail(String email, String password)
-Future\~void\~ signOut()
-Stream authStateChanges()
}

class FirebaseQuestionRepository {
-Future\~List\~Question\~\~ getQuestions(int limit, int categoryID)
}

class FirebaseQuizRepository {
-Future\~List\~Quiz\~\~ getQuizList()
}

class FirebaseProfileRepository {
-Future\~ProfileData\~ getProfileData(String uid)
-Future\~void\~ updateProfileData(ProfileData profileData)
}

class FirebaseLeaderboardRepository {
-Future\~List\~ProfileData\~\~ getLeaderboard(String quizId)
}

class FirebaseAchievementRepository {
-Future\~List\~Achievement\~\~ getAchievements(ProfileData profileData)
-Future\~void\~ updateAchievements(ProfileData profileData, SessionData gameResult)
}

class FirebaseSessionRepository {
-Future\~SessionData\~ createMultiplayerSession(String categoryId, String playerName)
-Future\~SessionData\~ joinMultiplayerSession(String sessionId, String playerName)
-Stream getSessionStream(String sessionId)
-Future\~void\~ updatePlayerScore(String sessionId, String playerName, int score)
-Future\~void\~ updateSessionStatus(String sessionId, String status)
}

class FirebaseOptionsRepository {
-Future\~void\~ saveOptions(UserOptions options)
-Future\~UserOptions\~ getOptions()
-Future\~void\~ saveUIOptions(UIOptions options)
-Future\~UIOptions\~ loadUIOptions()
}

%% Serwisy --> Repozytoria Firebase (dependency)
AuthLoginService --> FirebaseAuthRepository : uses
AuthRegisterService --> FirebaseAuthRepository : uses
AuthRegisterService --> FirebaseProfileRepository : uses
QuestionService --> FirebaseQuestionRepository : uses
SingleplayerGameService --> FirebaseSessionRepository : uses
SingleplayerGameService --> FirebaseQuestionRepository : uses
MultiplayerGameService --> FirebaseSessionRepository : uses
MultiplayerGameService --> FirebaseQuestionRepository : uses
PrivateGameCreationService --> FirebaseSessionRepository : uses
PrivateGameJoinService --> FirebaseSessionRepository : uses
GameOptionsService --> FirebaseOptionsRepository : uses
UserOptionsService --> FirebaseOptionsRepository : uses
UIOptionsService --> FirebaseOptionsRepository : uses
LeaderboardService --> FirebaseLeaderboardRepository : uses
LeaderboardService --> FirebaseProfileRepository : uses
AchievementService --> FirebaseAchievementRepository : uses
QuizListService --> FirebaseQuizRepository : uses
ProfileDataService --> FirebaseProfileRepository : uses
ScoreTableService --> FirebaseSessionRepository : uses

%% Repozytoria zwracają modele danych
FirebaseAuthRepository ..> ProfileData : returns
FirebaseProfileRepository ..> ProfileData : returns
FirebaseQuestionRepository ..> Question : returns
FirebaseSessionRepository ..> SessionData : returns
FirebaseLeaderboardRepository ..> ProfileData : returns

%% Interfejsy serwisów używają modeli danych
IGameOptionsService ..> PrivateGameOptions : uses
IUserOptionsService ..> UserOptions : uses
IUIOptionsService ..> UIOptions : uses
ISingleplayerGameService ..> SessionData : uses
ISingleplayerGameService ..> Question : uses
IMultiplayerGameService ..> SessionData : uses
IMultiplayerGameService ..> Question : uses
IMultiplayerGameService ..> Player : uses
IPrivateGameCreationService ..> SessionData : uses
IPrivateGameJoinService ..> SessionData : uses
ILeaderboardService ..> ProfileData : uses
IAchievementService ..> ProfileData : uses
IRegisterAuthService ..> ProfileData : uses
IProfileDataService ..> ProfileData : uses
IScoreTableService ..> SessionData : uses

```

