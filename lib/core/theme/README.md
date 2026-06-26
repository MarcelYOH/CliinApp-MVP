# core/theme/ — Réservé

Ce dossier est prévu pour centraliser la configuration du thème Material de l'app.

## Contenu futur prévu

- `app_theme.dart` — ThemeData clair (light theme) basé sur AppColors et AppTextStyles
- `app_dark_theme.dart` — ThemeData sombre (dark mode, si activé)
- `app_typography.dart` — TextTheme Material consolidé depuis AppTextStyles

## État actuel

Le thème est défini inline dans `main.dart` (MaterialApp) et via les constantes
dans `core/constants/` (AppColors, AppTextStyles, AppConstants).
Ce dossier est vide jusqu'à ce que la migration vers ThemeData soit engagée.
