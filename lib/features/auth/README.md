# Module Auth — Non implémenté

Ce module est prévu pour la phase suivante du projet (post-financement pilote).
Il gérera l'authentification des utilisateurs citoyens et des intervenants.

## Sous-dossiers prévus

| Dossier    | Rôle futur                                                          |
|------------|---------------------------------------------------------------------|
| `data/`    | Sources de données : AuthRepository (Firebase Auth ou équivalent)  |
| `models/`  | UserModel étendu (rôle, permissions, token), SessionModel           |
| `pages/`   | LoginPage, RegisterPage, ForgotPasswordPage                         |
| `store/`   | AuthStore (ChangeNotifier) — gestion de la session active           |
| `widgets/` | Composants UI réutilisables : AuthTextField, SocialLoginButton, ... |

## Point d'intégration

Une fois implémenté, `AuthStore.instance.currentUser` remplacera
`DummyUser.currentUser` dans `home_page.dart` et `take_charge_flow.dart`.
