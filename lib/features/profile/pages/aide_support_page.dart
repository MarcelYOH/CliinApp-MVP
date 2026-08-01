// lib/features/profile/pages/aide_support_page.dart
// Entrée "Aide et support" du Profil — FAQ (accordéon), Guides (accordéon,
// style carte) et Contactez-nous (mailto), tout sur une seule page
// scrollable, sans sous-pages séparées.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/circle_icon_button.dart';

const String _kSupportEmail = 'cliinapp.support@gmail.com';

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry(this.question, this.answer);
}

const List<_FaqEntry> _kFaqEntries = [
  _FaqEntry(
    'Comment signaler un cas d\'insalubrité ?',
    'Appuyez sur le bouton "Signaler" (accessible en permanence en bas de '
        'l\'écran, où que vous soyez dans l\'application), prenez une photo du '
        'problème, choisissez la catégorie qui correspond le mieux, précisez '
        'la provenance et le niveau d\'urgence, ajoutez une description si '
        'besoin, puis validez. Votre position est automatiquement détectée '
        'pour localiser le cas.',
  ),
  _FaqEntry(
    'Comment prendre en charge un cas signalé ?',
    'Ouvrez le détail d\'un cas au statut "Disponible" et appuyez sur '
        '"Prendre en charge". Vous devenez alors responsable de résoudre ce '
        'problème. Une fois l\'action terminée sur le terrain, vous devrez '
        'soumettre une photo de preuve pour valider la résolution.',
  ),
  _FaqEntry(
    'Qu\'est-ce qu\'un groupe et comment le rejoindre ?',
    'Un groupe est un collectif (association, ONG, groupe de bénévoles) qui '
        'coordonne des actions citoyennes contre l\'insalubrité. Pour '
        'rejoindre un groupe, ouvrez son profil et appuyez sur "Suivre" — '
        'vous pourrez alors signaler des cas en son nom et participer à ses '
        'actions.',
  ),
  _FaqEntry(
    'Comment fonctionne le mode anonyme ?',
    'À la publication d\'un signalement, vous pouvez choisir "Anonyme" — '
        'votre identité ne sera alors visible par personne. C\'est utile si '
        'vous préférez rester discret sur un signalement particulier.',
  ),
  _FaqEntry(
    'Pourquoi mon cas redevient-il "Disponible" après avoir été pris en '
        'charge ?',
    'Si l\'intervenant qui a pris en charge votre cas abandonne (délai '
        'dépassé ou choix volontaire) ou si sa preuve est rejetée, le cas '
        'redevient automatiquement disponible pour qu\'un autre intervenant '
        'puisse le traiter. Vous recevez une notification à chaque fois que '
        'cela se produit.',
  ),
  _FaqEntry(
    'Que signifie le bouton "Participer" sur une action terrain ?',
    'Cliquer sur "Participer à cette action" informe simplement '
        'l\'organisateur que vous comptez être présent lors de l\'action '
        '(nettoyage, sensibilisation...). Cela n\'engage aucune prise en '
        'charge de cas ni aucune gestion — c\'est uniquement une annonce de '
        'présence, pour aider l\'organisateur à estimer le nombre de '
        'personnes mobilisées. Vous pouvez annuler votre participation à '
        'tout moment.',
  ),
];

class _GuideEntry {
  final String title;
  final IconData icon;
  final String content;
  const _GuideEntry(this.title, this.icon, this.content);
}

const List<_GuideEntry> _kGuideEntries = [
  _GuideEntry(
    'Bien démarrer sur CliinApp',
    Icons.rocket_launch_rounded,
    '1. Créez votre compte avec votre numéro de téléphone\n'
        '2. Autorisez la localisation pour voir les cas près de chez vous\n'
        '3. Explorez la carte ou la page d\'accueil pour découvrir les '
        'signalements de votre quartier\n'
        '4. Signalez votre premier cas d\'insalubrité, ou rejoignez un '
        'groupe déjà actif dans votre zone',
  ),
  _GuideEntry(
    'Bien remplir un signalement',
    Icons.edit_note_rounded,
    '• Prenez une photo claire et représentative du problème\n'
        '• Choisissez la catégorie la plus précise possible, ainsi que le '
        'niveau d\'urgence et la provenance du problème\n'
        '• Une description courte mais précise du problème aide à mieux '
        'comprendre l\'urgence',
  ),
  _GuideEntry(
    'Créer et faire vivre un groupe',
    Icons.groups_rounded,
    '• Donnez un nom clair, une photo de couverture et un logo '
        'représentatifs de votre identité visuelle\n'
        '• Complétez la section "Nos besoins" pour indiquer ce dont votre '
        'groupe a besoin (bénévoles, matériel, financement...)\n'
        '• Organisez régulièrement des actions terrain pour mobiliser vos '
        'membres et gagner en visibilité (badges Engagé, Impact, Officiel)',
  ),
];

class AideSupportPage extends StatelessWidget {
  const AideSupportPage({super.key});

  Future<void> _contactByEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _kSupportEmail);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune application email disponible.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email.'),
            backgroundColor: CliinAppColors.alertRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CliinAppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  CliinAppConstants.pagePadding,
                  CliinAppConstants.spacingM,
                  CliinAppConstants.pagePadding,
                  MediaQuery.of(context).padding.bottom +
                      CliinAppConstants.spacingXL,
                ),
                children: [
                  _buildSectionTitle('FAQ'),
                  const SizedBox(height: CliinAppConstants.spacingS),
                  _buildFaqSection(),
                  const SizedBox(height: CliinAppConstants.spacingXL),
                  _buildSectionTitle('Guides'),
                  const SizedBox(height: CliinAppConstants.spacingS),
                  _buildGuidesSection(),
                  const SizedBox(height: CliinAppConstants.spacingXL),
                  _buildSectionTitle('Contactez-nous'),
                  const SizedBox(height: CliinAppConstants.spacingS),
                  _buildContactCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 12),
      child: Row(
        children: [
          CircleIconButton.back(
            onTap: () => Navigator.pop(context),
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Aide et support',
                style: CliinAppTextStyles.headingMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: CliinAppTextStyles.headingSmall);
  }

  Widget _buildFaqSection() {
    return Container(
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _kFaqEntries.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: CliinAppColors.divider),
            ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              title: Text(
                _kFaqEntries[i].question,
                style: CliinAppTextStyles.headingSmall.copyWith(fontSize: 13),
              ),
              iconColor: CliinAppColors.primary,
              collapsedIconColor: CliinAppColors.textSecondary,
              childrenPadding: const EdgeInsets.fromLTRB(
                  16, 0, 16, CliinAppConstants.spacingM),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kFaqEntries[i].answer,
                  style: CliinAppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidesSection() {
    return Column(
      children: [
        for (var i = 0; i < _kGuideEntries.length; i++)
          Padding(
            padding: EdgeInsets.only(
                bottom: i < _kGuideEntries.length - 1
                    ? CliinAppConstants.spacingM
                    : 0),
            child: _buildGuideCard(_kGuideEntries[i]),
          ),
      ],
    );
  }

  Widget _buildGuideCard(_GuideEntry guide) {
    return Container(
      decoration: BoxDecoration(
        color: CliinAppColors.cardWhite,
        borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
        border: Border.all(color: CliinAppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: CliinAppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(guide.icon, color: CliinAppColors.primary, size: 18),
        ),
        title: Text(guide.title, style: CliinAppTextStyles.headingSmall),
        iconColor: CliinAppColors.primary,
        collapsedIconColor: CliinAppColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(
            16, 0, 16, CliinAppConstants.spacingM),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(guide.content, style: CliinAppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _contactByEmail(context),
      child: Container(
        padding: const EdgeInsets.all(CliinAppConstants.spacingM),
        decoration: BoxDecoration(
          color: CliinAppColors.cardWhite,
          borderRadius: BorderRadius.circular(CliinAppConstants.radiusMedium),
          border: Border.all(color: CliinAppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: CliinAppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_outlined,
                  color: CliinAppColors.primary, size: 18),
            ),
            const SizedBox(width: CliinAppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contactez-nous par email',
                      style: CliinAppTextStyles.headingSmall.copyWith(
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(_kSupportEmail, style: CliinAppTextStyles.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: CliinAppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
