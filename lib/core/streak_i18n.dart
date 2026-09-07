import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Teksten voor de dagelijkse reeks en vismaat-uitnodiging (6 talen).
const Map<String, Map<String, String>> _sL = {
  'streak_title': {'nl': 'Dagelijkse reeks', 'en': 'Daily streak', 'de': 'Tägliche Serie', 'fr': 'Série quotidienne', 'es': 'Racha diaria', 'pl': 'Codzienna seria'},
  'days': {'nl': 'dagen', 'en': 'days', 'de': 'Tage', 'fr': 'jours', 'es': 'días', 'pl': 'dni'},
  'day': {'nl': 'dag', 'en': 'day', 'de': 'Tag', 'fr': 'jour', 'es': 'día', 'pl': 'dzień'},
  'today_done': {'nl': 'Vandaag gedaan ✓', 'en': 'Done for today ✓', 'de': 'Heute erledigt ✓', 'fr': 'Fait pour aujourd\'hui ✓', 'es': 'Hecho por hoy ✓', 'pl': 'Dziś zaliczone ✓'},
  'today_todo': {'nl': 'Vandaag nog: bijtkans = +1 dobber', 'en': 'Today: bite chance = +1 bobber', 'de': 'Heute: Beißchance = +1 Pose', 'fr': 'Aujourd\'hui : touche = +1 flotteur', 'es': 'Hoy: picada = +1 boya', 'pl': 'Dziś: branie = +1 spławik'},
  'start': {'nl': 'Bekijk de bijtkans: +1 dobber', 'en': 'Check the bite chance: +1 bobber', 'de': 'Beißchance ansehen: +1 Pose', 'fr': 'Regarde la chance de touche : +1 flotteur', 'es': 'Mira la picada: +1 boya', 'pl': 'Sprawdź branie: +1 spławik'},
  'longest': {'nl': 'Langste reeks', 'en': 'Longest streak', 'de': 'Längste Serie', 'fr': 'Plus longue série', 'es': 'Racha más larga', 'pl': 'Najdłuższa seria'},
  'rules': {'nl': 'Elke dag één vis-handeling (bijtkans, water, vangst of reactie) = +1 dobber. Elke volle week +10 dobbers. Eén misser per week mag.', 'en': 'One fishing action a day (bite chance, water, catch or comment) = +1 bobber. Every full week +10 bobbers. One miss per week is allowed.', 'de': 'Eine Angel-Aktion pro Tag (Beißchance, Gewässer, Fang oder Kommentar) = +1 Pose. Jede volle Woche +10 Posen. Ein Aussetzer pro Woche ist erlaubt.', 'fr': 'Une action pêche par jour (chance de touche, plan d\'eau, prise ou commentaire) = +1 flotteur. Chaque semaine complète +10 flotteurs. Un oubli par semaine est permis.', 'es': 'Una acción de pesca al día (picada, agua, captura o comentario) = +1 boya. Cada semana completa +10 boyas. Se permite un fallo por semana.', 'pl': 'Jedna czynność dziennie (branie, woda, połów lub komentarz) = +1 spławik. Każdy pełny tydzień +10 spławików. Jedno pominięcie w tygodniu jest dozwolone.'},
  'bonus_in': {'nl': 'Nog %d dagen tot de weekbonus (+10)', 'en': '%d more days to the weekly bonus (+10)', 'de': 'Noch %d Tage bis zum Wochenbonus (+10)', 'fr': 'Encore %d jours avant le bonus hebdo (+10)', 'es': '%d días más para el bono semanal (+10)', 'pl': 'Jeszcze %d dni do bonusu tygodniowego (+10)'},
  'bonus_today': {'nl': 'Weekbonus vandaag: +10 dobbers!', 'en': 'Weekly bonus today: +10 bobbers!', 'de': 'Wochenbonus heute: +10 Posen!', 'fr': 'Bonus hebdo aujourd\'hui : +10 flotteurs !', 'es': '¡Bono semanal hoy: +10 boyas!', 'pl': 'Bonus tygodniowy dziś: +10 spławików!'},
  'freeze_used': {'nl': 'Vrije misser van deze week gebruikt', 'en': 'Free miss of this week used', 'de': 'Freier Aussetzer dieser Woche genutzt', 'fr': 'Oubli gratuit de la semaine utilisé', 'es': 'Fallo libre de esta semana usado', 'pl': 'Wolne pominięcie w tym tygodniu wykorzystane'},
  'at_risk': {'nl': 'Je reeks loopt vanavond af!', 'en': 'Your streak ends tonight!', 'de': 'Deine Serie endet heute Abend!', 'fr': 'Ta série se termine ce soir !', 'es': '¡Tu racha termina esta noche!', 'pl': 'Twoja seria kończy się dziś wieczorem!'},
  'invite_title': {'nl': 'Vismaat uitnodigen', 'en': 'Invite a fishing buddy', 'de': 'Angelfreund einladen', 'fr': 'Inviter un copain de pêche', 'es': 'Invitar a un compañero de pesca', 'pl': 'Zaproś kolegę'},
  'invite_text': {'nl': 'Jullie krijgen allebei %d dobbers zodra je vismaat z\'n eerste vangst logt.', 'en': 'You both get %d bobbers once your buddy logs a first catch.', 'de': 'Ihr bekommt beide %d Posen, sobald dein Freund den ersten Fang loggt.', 'fr': 'Vous recevez chacun %d flotteurs dès la première prise de ton copain.', 'es': 'Los dos recibís %d boyas en cuanto tu compañero registre su primera captura.', 'pl': 'Oboje dostaniecie %d spławików, gdy kolega zapisze pierwszy połów.'},
  'your_code': {'nl': 'Jouw code', 'en': 'Your code', 'de': 'Dein Code', 'fr': 'Ton code', 'es': 'Tu código', 'pl': 'Twój kod'},
  'share': {'nl': 'Uitnodiging delen', 'en': 'Share invite', 'de': 'Einladung teilen', 'fr': 'Partager l\'invitation', 'es': 'Compartir invitación', 'pl': 'Udostępnij zaproszenie'},
  'share_msg': {'nl': 'Ik zit op YessFish, de app voor vissers: viskaart, bijtkans, vangsten loggen. Meld je aan met mijn code %s dan krijgen we allebei %d dobbers. %s', 'en': 'I\'m on YessFish, the app for anglers: fishing map, bite chance, catch log. Sign up with my code %s and we both get %d bobbers. %s', 'de': 'Ich bin bei YessFish, der App für Angler: Gewässerkarte, Beißchance, Fangbuch. Melde dich mit meinem Code %s an, dann bekommen wir beide %d Posen. %s', 'fr': 'Je suis sur YessFish, l\'appli des pêcheurs : carte, chance de touche, carnet de prises. Inscris-toi avec mon code %s et on reçoit chacun %d flotteurs. %s', 'es': 'Estoy en YessFish, la app para pescadores: mapa, probabilidad de picada, registro de capturas. Regístrate con mi código %s y los dos recibimos %d boyas. %s', 'pl': 'Jestem na YessFish, aplikacji dla wędkarzy: mapa, szansa na branie, dziennik połowów. Zarejestruj się z moim kodem %s, a oboje dostaniemy %d spławików. %s'},
  'stats': {'nl': '%d uitgenodigd · %d beloond', 'en': '%d invited · %d rewarded', 'de': '%d eingeladen · %d belohnt', 'fr': '%d invités · %d récompensés', 'es': '%d invitados · %d recompensados', 'pl': '%d zaproszonych · %d nagrodzonych'},
  'have_code': {'nl': 'Zelf een code gekregen?', 'en': 'Got a code yourself?', 'de': 'Selbst einen Code erhalten?', 'fr': 'Tu as reçu un code ?', 'es': '¿Te han dado un código?', 'pl': 'Masz kod?'},
  'enter_code': {'nl': 'Code invullen', 'en': 'Enter code', 'de': 'Code eingeben', 'fr': 'Saisir le code', 'es': 'Introducir código', 'pl': 'Wpisz kod'},
  'code_hint': {'nl': 'Uitnodigingscode van je vismaat', 'en': 'Your buddy\'s invite code', 'de': 'Einladungscode deines Freundes', 'fr': 'Code d\'invitation de ton copain', 'es': 'Código de invitación de tu compañero', 'pl': 'Kod zaproszenia od kolegi'},
  'ok': {'nl': 'Koppelen', 'en': 'Link', 'de': 'Verknüpfen', 'fr': 'Lier', 'es': 'Vincular', 'pl': 'Połącz'},
  'cancel': {'nl': 'Annuleren', 'en': 'Cancel', 'de': 'Abbrechen', 'fr': 'Annuler', 'es': 'Cancelar', 'pl': 'Anuluj'},
  'copied': {'nl': 'Code gekopieerd', 'en': 'Code copied', 'de': 'Code kopiert', 'fr': 'Code copié', 'es': 'Código copiado', 'pl': 'Kod skopiowany'},
  'wd': {'nl': 'M,D,W,D,V,Z,Z', 'en': 'M,T,W,T,F,S,S', 'de': 'M,D,M,D,F,S,S', 'fr': 'L,M,M,J,V,S,D', 'es': 'L,M,X,J,V,S,D', 'pl': 'P,W,Ś,C,P,S,N'},
};

String sti(BuildContext c, String k) {
  final l = Provider.of<I18n>(c, listen: false).locale;
  return _sL[k]?[l] ?? _sL[k]?['en'] ?? k;
}
