import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Self-contained 6-talige teksten voor de Vistijl-tools (NL/EN/DE/FR/ES/PL).
/// Bewust los van de centrale vertaalbestanden, net als onboarding_i18n.dart en
/// disciplines_i18n.dart. 1-op-1 geport uit de web-dicts (T/P/POPT/TIPT/RIGT +
/// Knowledge KNOW/KNOW_MEDIA + CHECKLIST). Niets verzonnen.

// ── Platte UI-strings: key → { locale → tekst } ──────────────────────────────
const Map<String, Map<String, String>> kVttStrings = {
  // Paginachrome
  'title': {'nl': 'Vistijl-tools', 'en': 'Style tools', 'de': 'Stil-Tools', 'fr': 'Outils par style', 'es': 'Herramientas por estilo', 'pl': 'Narzędzia stylu'},
  'pickFirst': {'nl': 'Kies eerst je visstijlen om de bijbehorende tools te zien.', 'en': 'Choose your fishing styles first to see their tools.', 'de': 'Wähle zuerst deine Angelstile, um die Tools zu sehen.', 'fr': "Choisissez d'abord vos styles pour voir leurs outils.", 'es': 'Elige primero tus estilos para ver sus herramientas.', 'pl': 'Najpierw wybierz style, aby zobaczyć narzędzia.'},
  'more': {'nl': 'Meer tools per vistijl volgen.', 'en': 'More tools per style are on the way.', 'de': 'Weitere Tools pro Stil folgen.', 'fr': "D'autres outils par style arrivent.", 'es': 'Más herramientas por estilo en camino.', 'pl': 'Więcej narzędzi wkrótce.'},
  'pickLink': {'nl': 'Naar visstijlen', 'en': 'To fishing styles', 'de': 'Zu den Angelstilen', 'fr': 'Vers les styles', 'es': 'A los estilos', 'pl': 'Do stylów'},

  // ── Karper · Sessie- & voerplanner ──
  'carp': {'nl': 'Karper · Sessie- & voerplanner', 'en': 'Carp · Session & bait planner', 'de': 'Karpfen · Session- & Futterplaner', 'fr': 'Carpe · Planificateur session & amorce', 'es': 'Carpa · Planificador de sesión y cebo', 'pl': 'Karp · Planer sesji i zanęty'},
  'nights': {'nl': 'Nachten', 'en': 'Nights', 'de': 'Nächte', 'fr': 'Nuits', 'es': 'Noches', 'pl': 'Noce'},
  'rods': {'nl': 'Hengels', 'en': 'Rods', 'de': 'Ruten', 'fr': 'Cannes', 'es': 'Cañas', 'pl': 'Wędki'},
  'activity': {'nl': 'Activiteit', 'en': 'Activity', 'de': 'Aktivität', 'fr': 'Activité', 'es': 'Actividad', 'pl': 'Aktywność'},
  'low': {'nl': 'Laag', 'en': 'Low', 'de': 'Niedrig', 'fr': 'Faible', 'es': 'Baja', 'pl': 'Niska'},
  'normal': {'nl': 'Normaal', 'en': 'Normal', 'de': 'Normal', 'fr': 'Normale', 'es': 'Normal', 'pl': 'Normalna'},
  'high': {'nl': 'Hoog', 'en': 'High', 'de': 'Hoch', 'fr': 'Élevée', 'es': 'Alta', 'pl': 'Wysoka'},
  'feed': {'nl': 'Voer (boilie + partikel)', 'en': 'Bait (boilie + particle)', 'de': 'Futter (Boilie + Partikel)', 'fr': 'Amorce (bouillette + graine)', 'es': 'Cebo (boilie + partícula)', 'pl': 'Zanęta (kulki + ziarno)'},
  'pva': {'nl': 'PVA-zakjes', 'en': 'PVA bags', 'de': 'PVA-Beutel', 'fr': 'Sacs PVA', 'es': 'Bolsas PVA', 'pl': 'Woreczki PVA'},
  'checklist': {'nl': 'Checklist', 'en': 'Checklist', 'de': 'Checkliste', 'fr': 'Checklist', 'es': 'Checklist', 'pl': 'Lista'},

  // ── Feeder · Korfgewicht-adviseur ──
  'feeder': {'nl': 'Feeder · Korfgewicht-adviseur', 'en': 'Feeder · Feeder-weight adviser', 'de': 'Feeder · Korbgewicht-Berater', 'fr': 'Feeder · Conseiller de plomb', 'es': 'Feeder · Asesor de peso', 'pl': 'Feeder · Doradca ciężaru kosza'},
  'flow': {'nl': 'Stroming', 'en': 'Current', 'de': 'Strömung', 'fr': 'Courant', 'es': 'Corriente', 'pl': 'Prąd'},
  'none': {'nl': 'Geen', 'en': 'None', 'de': 'Keine', 'fr': 'Aucun', 'es': 'Ninguna', 'pl': 'Brak'},
  'light': {'nl': 'Licht', 'en': 'Light', 'de': 'Leicht', 'fr': 'Léger', 'es': 'Ligera', 'pl': 'Lekki'},
  'mod': {'nl': 'Matig', 'en': 'Moderate', 'de': 'Mäßig', 'fr': 'Modéré', 'es': 'Moderada', 'pl': 'Umiarkowany'},
  'strong': {'nl': 'Sterk', 'en': 'Strong', 'de': 'Stark', 'fr': 'Fort', 'es': 'Fuerte', 'pl': 'Silny'},
  'depth': {'nl': 'Diepte (m)', 'en': 'Depth (m)', 'de': 'Tiefe (m)', 'fr': 'Profondeur (m)', 'es': 'Profundidad (m)', 'pl': 'Głębokość (m)'},
  'dist': {'nl': 'Afstand', 'en': 'Distance', 'de': 'Distanz', 'fr': 'Distance', 'es': 'Distancia', 'pl': 'Odległość'},
  'short': {'nl': 'Kort', 'en': 'Short', 'de': 'Kurz', 'fr': 'Courte', 'es': 'Corta', 'pl': 'Krótka'},
  'mid': {'nl': 'Middel', 'en': 'Mid', 'de': 'Mittel', 'fr': 'Moyenne', 'es': 'Media', 'pl': 'Średnia'},
  'far': {'nl': 'Ver', 'en': 'Far', 'de': 'Weit', 'fr': 'Longue', 'es': 'Larga', 'pl': 'Daleka'},
  'weight': {'nl': 'Aanbevolen korfgewicht', 'en': 'Recommended feeder weight', 'de': 'Empfohlenes Korbgewicht', 'fr': 'Poids de cage conseillé', 'es': 'Peso de cesta recomendado', 'pl': 'Zalecany ciężar kosza'},
  'feederTip': {'nl': 'Kies het lichtste gewicht dat je stek net houdt. Check de stromingslaag op de kaart.', 'en': 'Use the lightest weight that holds your spot. Check the current layer on the map.', 'de': 'Nimm das leichteste Gewicht, das deinen Platz hält. Prüfe die Strömungsebene auf der Karte.', 'fr': 'Prenez le poids le plus léger qui tient votre coup. Voyez la couche de courant sur la carte.', 'es': 'Usa el peso más ligero que aguante tu puesto. Mira la capa de corriente en el mapa.', 'pl': 'Użyj najlżejszego ciężaru, który utrzyma stanowisko. Sprawdź warstwę prądu na mapie.'},

  // ── Roofvis · Kunstaas-adviseur ──
  'pred': {'nl': 'Roofvis · Kunstaas-adviseur', 'en': 'Predator · Lure adviser', 'de': 'Raubfisch · Köderberater', 'fr': 'Carnassier · Conseiller de leurre', 'es': 'Depredador · Asesor de señuelo', 'pl': 'Drapieżnik · Doradca przynęty'},
  'temp': {'nl': 'Watertemp.', 'en': 'Water temp.', 'de': 'Wassertemp.', 'fr': 'Temp. eau', 'es': 'Temp. agua', 'pl': 'Temp. wody'},
  'cold': {'nl': 'Koud (<8°)', 'en': 'Cold (<8°)', 'de': 'Kalt (<8°)', 'fr': 'Froide (<8°)', 'es': 'Fría (<8°)', 'pl': 'Zimna (<8°)'},
  'cool': {'nl': 'Fris (8–15°)', 'en': 'Cool (8–15°)', 'de': 'Kühl (8–15°)', 'fr': 'Fraîche (8–15°)', 'es': 'Fresca (8–15°)', 'pl': 'Chłodna (8–15°)'},
  'warm': {'nl': 'Warm (>15°)', 'en': 'Warm (>15°)', 'de': 'Warm (>15°)', 'fr': 'Chaude (>15°)', 'es': 'Cálida (>15°)', 'pl': 'Ciepła (>15°)'},
  'clarity': {'nl': 'Helderheid', 'en': 'Clarity', 'de': 'Klarheit', 'fr': 'Clarté', 'es': 'Claridad', 'pl': 'Przejrzystość'},
  'clear': {'nl': 'Helder', 'en': 'Clear', 'de': 'Klar', 'fr': 'Claire', 'es': 'Clara', 'pl': 'Czysta'},
  'murky': {'nl': 'Troebel', 'en': 'Murky', 'de': 'Trüb', 'fr': 'Trouble', 'es': 'Turbia', 'pl': 'Mętna'},
  'depthL': {'nl': 'Diepte', 'en': 'Depth', 'de': 'Tiefe', 'fr': 'Profondeur', 'es': 'Profundidad', 'pl': 'Głębokość'},
  'shallow': {'nl': 'Ondiep', 'en': 'Shallow', 'de': 'Flach', 'fr': 'Peu profond', 'es': 'Somera', 'pl': 'Płytko'},
  'deep': {'nl': 'Diep', 'en': 'Deep', 'de': 'Tief', 'fr': 'Profond', 'es': 'Profunda', 'pl': 'Głęboko'},
  'lure': {'nl': 'Aastype', 'en': 'Lure type', 'de': 'Ködertyp', 'fr': 'Type de leurre', 'es': 'Tipo de señuelo', 'pl': 'Typ przynęty'},
  'color': {'nl': 'Kleur', 'en': 'Colour', 'de': 'Farbe', 'fr': 'Couleur', 'es': 'Color', 'pl': 'Kolor'},
  'retrieve': {'nl': 'Inhaalsnelheid', 'en': 'Retrieve', 'de': 'Einholtempo', 'fr': 'Récupération', 'es': 'Recuperación', 'pl': 'Prowadzenie'},
  'pl_coldDeep': {'nl': 'Langzame shad / jig, diep', 'en': 'Slow shad / jig, deep', 'de': 'Langsamer Shad / Jig, tief', 'fr': 'Shad / jig lent, profond', 'es': 'Shad / jig lento, profundo', 'pl': 'Wolny shad / jig, głęboko'},
  'pl_coldShallow': {'nl': 'Langzame jerkbait', 'en': 'Slow jerkbait', 'de': 'Langsamer Jerkbait', 'fr': 'Jerkbait lent', 'es': 'Jerkbait lento', 'pl': 'Wolny jerkbait'},
  'pl_warmShallow': {'nl': 'Topwater / spinnerbait', 'en': 'Topwater / spinnerbait', 'de': 'Topwater / Spinnerbait', 'fr': 'Topwater / spinnerbait', 'es': 'Topwater / spinnerbait', 'pl': 'Topwater / spinnerbait'},
  'pl_warmDeep': {'nl': 'Snelle crankbait', 'en': 'Fast crankbait', 'de': 'Schneller Crankbait', 'fr': 'Crankbait rapide', 'es': 'Crankbait rápido', 'pl': 'Szybki crankbait'},
  'pl_mid': {'nl': 'Shad of spinner, medium', 'en': 'Shad or spinner, medium', 'de': 'Shad oder Spinner, mittel', 'fr': 'Shad ou spinner, moyen', 'es': 'Shad o spinner, medio', 'pl': 'Shad lub spinner, średnio'},
  'pc_clear': {'nl': 'Naturel (wit/blauw/voorn)', 'en': 'Natural (white/blue/roach)', 'de': 'Natürlich (Weiß/Blau/Rotauge)', 'fr': 'Naturel (blanc/bleu/gardon)', 'es': 'Natural (blanco/azul/bermejuela)', 'pl': 'Naturalny (biały/niebieski/płoć)'},
  'pc_murky': {'nl': 'Fel (chartreuse/oranje/zwart)', 'en': 'Bright (chartreuse/orange/black)', 'de': 'Grell (Chartreuse/Orange/Schwarz)', 'fr': 'Vif (chartreuse/orange/noir)', 'es': 'Vivo (chartreuse/naranja/negro)', 'pl': 'Jaskrawy (chartreuse/pomarańcz/czarny)'},
  'pr_cold': {'nl': 'Traag, met pauzes', 'en': 'Slow, with pauses', 'de': 'Langsam, mit Pausen', 'fr': 'Lente, avec pauses', 'es': 'Lenta, con pausas', 'pl': 'Wolno, z pauzami'},
  'pr_warm': {'nl': 'Snel & agressief', 'en': 'Fast & aggressive', 'de': 'Schnell & aggressiv', 'fr': 'Rapide & agressive', 'es': 'Rápida y agresiva', 'pl': 'Szybko i agresywnie'},
  'pr_mid': {'nl': 'Wisselend tempo', 'en': 'Varied tempo', 'de': 'Wechselndes Tempo', 'fr': 'Tempo varié', 'es': 'Ritmo variado', 'pl': 'Zmienne tempo'},

  // ── Witvis · Wedstrijd-rekenaar ──
  'coarse': {'nl': 'Witvis · Wedstrijd-rekenaar', 'en': 'Coarse · Match calculator', 'de': 'Weißfisch · Wettkampf-Rechner', 'fr': 'Blanc · Calculateur de concours', 'es': 'Blanco · Calculadora de concurso', 'pl': 'Biała ryba · Kalkulator zawodów'},
  'totalW': {'nl': 'Totaalgewicht (kg)', 'en': 'Total weight (kg)', 'de': 'Gesamtgewicht (kg)', 'fr': 'Poids total (kg)', 'es': 'Peso total (kg)', 'pl': 'Waga łączna (kg)'},
  'hours': {'nl': 'Uren', 'en': 'Hours', 'de': 'Stunden', 'fr': 'Heures', 'es': 'Horas', 'pl': 'Godziny'},
  'perHour': {'nl': 'Gewicht per uur', 'en': 'Weight per hour', 'de': 'Gewicht pro Stunde', 'fr': 'Poids par heure', 'es': 'Peso por hora', 'pl': 'Waga na godzinę'},
  'coarseTip': {'nl': 'Bijvoeren: klein en vaak. Pas je ritme aan als de beten stoppen.', 'en': 'Feed little and often. Adjust your rhythm if bites stop.', 'de': 'Wenig und oft füttern. Rhythmus anpassen, wenn die Bisse ausbleiben.', 'fr': "Amorcez peu et souvent. Adaptez le rythme si les touches cessent.", 'es': 'Ceba poco y a menudo. Ajusta el ritmo si cesan las picadas.', 'pl': 'Nęć mało i często. Zmień rytm, gdy brań brak.'},

  // ── Streetfishing · Jigkop-adviseur ──
  'street': {'nl': 'Streetfishing · Jigkop-adviseur', 'en': 'Streetfishing · Jig-head adviser', 'de': 'Streetfishing · Jigkopf-Berater', 'fr': 'Streetfishing · Conseiller tête plombée', 'es': 'Streetfishing · Asesor de cabeza plomada', 'pl': 'Streetfishing · Doradca główki'},
  'streetOut': {'nl': 'Aanbevolen jigkop', 'en': 'Recommended jig head', 'de': 'Empfohlener Jigkopf', 'fr': 'Tête plombée conseillée', 'es': 'Cabeza plomada recomendada', 'pl': 'Zalecana główka jigowa'},
  'streetTip': {'nl': 'Ultralight: net genoeg om contact met de bodem te houden. Mobiel blijven, veel stekken proberen.', 'en': 'Ultralight: just enough to keep bottom contact. Stay mobile, try many spots.', 'de': 'Ultralight: gerade genug für Bodenkontakt. Mobil bleiben, viele Stellen testen.', 'fr': 'Ultraléger : juste assez pour garder le contact du fond. Restez mobile, essayez beaucoup de spots.', 'es': 'Ultraligero: lo justo para mantener contacto con el fondo. Sé móvil, prueba muchos puestos.', 'pl': 'Ultralight: tyle, by trzymać kontakt z dnem. Bądź mobilny, próbuj wielu miejsc.'},

  // ── Meerval · Methode & materiaal ──
  'catfish': {'nl': 'Meerval · Methode & materiaal', 'en': 'Catfish · Method & tackle', 'de': 'Wels · Methode & Gerät', 'fr': 'Silure · Méthode & matériel', 'es': 'Siluro · Método y equipo', 'pl': 'Sum · Metoda i sprzęt'},
  'method': {'nl': 'Methode', 'en': 'Method', 'de': 'Methode', 'fr': 'Méthode', 'es': 'Método', 'pl': 'Metoda'},
  'cf_drift_l': {'nl': 'Afdrijven', 'en': 'Drifting', 'de': 'Abtreiben', 'fr': 'Dérive', 'es': 'A la deriva', 'pl': 'Spław'},
  'cf_sensor_l': {'nl': 'Peiler/pose', 'en': 'Static/float', 'de': 'Stationär/Pose', 'fr': 'Poste fixe/flotteur', 'es': 'Fijo/flotador', 'pl': 'Stały/spławik'},
  'cf_clonk_l': {'nl': 'Klopstok', 'en': 'Clonk', 'de': 'Klopfholz', 'fr': 'Clonk', 'es': 'Clonk', 'pl': 'Klekotka'},
  'cf_bank_l': {'nl': 'Vanaf de kant', 'en': 'From the bank', 'de': 'Vom Ufer', 'fr': 'Du bord', 'es': 'Desde la orilla', 'pl': 'Z brzegu'},
  'cf_tip_drift': {'nl': 'Drijf met de stroom over diepe kuilen; aas net boven de bodem.', 'en': 'Drift with the flow over deep holes; bait just off the bottom.', 'de': 'Mit der Strömung über tiefe Löcher treiben; Köder knapp über Grund.', 'fr': 'Dérivez avec le courant sur les fosses ; appât près du fond.', 'es': 'Deriva con la corriente sobre fosas; cebo justo sobre el fondo.', 'pl': 'Spławiaj z prądem nad głębokimi dołami; przynęta tuż nad dnem.'},
  'cf_tip_sensor': {'nl': 'Vaste stek bij structuur; geduld, vooral warme nachten.', 'en': 'Static near structure; patience, especially warm nights.', 'de': 'Stationär an Struktur; Geduld, vor allem warme Nächte.', 'fr': 'Poste fixe près des structures ; patience, surtout nuits chaudes.', 'es': 'Fijo cerca de estructura; paciencia, sobre todo noches cálidas.', 'pl': 'Stałe stanowisko przy strukturze; cierpliwość, zwłaszcza ciepłe noce.'},
  'cf_tip_clonk': {'nl': 'Klopstok boven diep water; verticaal aanbieden.', 'en': 'Clonk over deep water; present vertically.', 'de': 'Klopfholz über tiefem Wasser; vertikal anbieten.', 'fr': "Clonk au-dessus de l'eau profonde ; présentation verticale.", 'es': 'Clonk sobre agua profunda; presenta en vertical.', 'pl': 'Klekotka nad głęboką wodą; prezentacja pionowa.'},
  'cf_tip_bank': {'nl': 'Werp naar overhangende oevers en instroom; stevig materiaal.', 'en': 'Cast to overhanging banks and inflows; strong tackle.', 'de': 'An Uferbewuchs und Einläufe werfen; starkes Gerät.', 'fr': "Lancez sous les berges et aux arrivées d'eau ; matériel solide.", 'es': 'Lanza a orillas colgantes y entradas de agua; equipo fuerte.', 'pl': 'Rzucaj pod nawisy i dopływy; mocny sprzęt.'},

  // ── Vliegvissen · Match-the-hatch ──
  'fly': {'nl': 'Vliegvissen · Match-the-hatch', 'en': 'Fly · Match-the-hatch', 'de': 'Fliegenfischen · Match-the-hatch', 'fr': 'Mouche · Match-the-hatch', 'es': 'Mosca · Match-the-hatch', 'pl': 'Mucha · Match-the-hatch'},
  'season': {'nl': 'Seizoen', 'en': 'Season', 'de': 'Saison', 'fr': 'Saison', 'es': 'Temporada', 'pl': 'Sezon'},
  'spring': {'nl': 'Lente', 'en': 'Spring', 'de': 'Frühling', 'fr': 'Printemps', 'es': 'Primavera', 'pl': 'Wiosna'},
  'summer': {'nl': 'Zomer', 'en': 'Summer', 'de': 'Sommer', 'fr': 'Été', 'es': 'Verano', 'pl': 'Lato'},
  'autumn': {'nl': 'Herfst', 'en': 'Autumn', 'de': 'Herbst', 'fr': 'Automne', 'es': 'Otoño', 'pl': 'Jesień'},
  'winter': {'nl': 'Winter', 'en': 'Winter', 'de': 'Winter', 'fr': 'Hiver', 'es': 'Invierno', 'pl': 'Zima'},
  'flyOut': {'nl': 'Aanbevolen vlieg', 'en': 'Recommended fly', 'de': 'Empfohlene Fliege', 'fr': 'Mouche conseillée', 'es': 'Mosca recomendada', 'pl': 'Zalecana mucha'},
  'fly_spring': {'nl': 'Nymfen + emergers, maat 14–16', 'en': 'Nymphs + emergers, size 14–16', 'de': 'Nymphen + Emerger, Größe 14–16', 'fr': 'Nymphes + émergentes, taille 14–16', 'es': 'Ninfas + emergentes, talla 14–16', 'pl': 'Nimfy + emergery, rozmiar 14–16'},
  'fly_summer': {'nl': 'Droge vliegen, maat 16–20', 'en': 'Dry flies, size 16–20', 'de': 'Trockenfliegen, Größe 16–20', 'fr': 'Sèches, taille 16–20', 'es': 'Secas, talla 16–20', 'pl': 'Suche muchy, rozmiar 16–20'},
  'fly_autumn': {'nl': 'Streamers + nymfen, maat 10–14', 'en': 'Streamers + nymphs, size 10–14', 'de': 'Streamer + Nymphen, Größe 10–14', 'fr': 'Streamers + nymphes, taille 10–14', 'es': 'Streamers + ninfas, talla 10–14', 'pl': 'Streamery + nimfy, rozmiar 10–14'},
  'fly_winter': {'nl': 'Zware nymfen, langzaam, maat 12–16', 'en': 'Heavy nymphs, slow, size 12–16', 'de': 'Schwere Nymphen, langsam, Größe 12–16', 'fr': 'Nymphes lourdes, lent, taille 12–16', 'es': 'Ninfas pesadas, lento, talla 12–16', 'pl': 'Ciężkie nimfy, wolno, rozmiar 12–16'},

  // ── Forel · Spinner/aas-adviseur ──
  'trout': {'nl': 'Forel · Spinner/aas-adviseur', 'en': 'Trout · Spinner/bait adviser', 'de': 'Forelle · Spinner/Köder-Berater', 'fr': 'Truite · Conseiller cuiller/appât', 'es': 'Trucha · Asesor cuchara/cebo', 'pl': 'Pstrąg · Doradca obrotówki/przynęty'},
  'venue': {'nl': 'Water', 'en': 'Water', 'de': 'Gewässer', 'fr': 'Eau', 'es': 'Agua', 'pl': 'Woda'},
  'pond': {'nl': 'Put', 'en': 'Pond', 'de': 'Teich', 'fr': 'Étang', 'es': 'Coto', 'pl': 'Łowisko'},
  'brook': {'nl': 'Beek', 'en': 'Brook', 'de': 'Bach', 'fr': 'Ruisseau', 'es': 'Arroyo', 'pl': 'Potok'},
  'trOut': {'nl': 'Aas/spinner', 'en': 'Bait/spinner', 'de': 'Köder/Spinner', 'fr': 'Appât/cuiller', 'es': 'Cebo/cuchara', 'pl': 'Przynęta/obrotówka'},
  'tr_cold': {'nl': 'Kleine spinner/spoon, langzaam', 'en': 'Small spinner/spoon, slow', 'de': 'Kleiner Spinner/Blinker, langsam', 'fr': 'Petite cuiller, lente', 'es': 'Cucharilla pequeña, lenta', 'pl': 'Mała obrotówka, wolno'},
  'tr_warm': {'nl': 'Spinner/spoon, sneller inhalen', 'en': 'Spinner/spoon, faster retrieve', 'de': 'Spinner/Blinker, schneller einholen', 'fr': 'Cuiller, récupération plus rapide', 'es': 'Cucharilla, recuperación más rápida', 'pl': 'Obrotówka, szybsze prowadzenie'},
  'tr_mid': {'nl': 'Mepps/spoon, wisselend tempo', 'en': 'Mepps/spoon, varied tempo', 'de': 'Mepps/Blinker, wechselndes Tempo', 'fr': 'Mepps/ondulante, tempo varié', 'es': 'Mepps/cuchara, ritmo variado', 'pl': 'Mepps/błystka, zmienne tempo'},

  // ── Zeevissen · Aas & montage ──
  'sea': {'nl': 'Zeevissen · Aas & montage', 'en': 'Sea · Bait & rig', 'de': 'Meeresangeln · Köder & Montage', 'fr': 'Mer · Appât & montage', 'es': 'Mar · Cebo y montaje', 'pl': 'Morze · Przynęta i zestaw'},
  'target': {'nl': 'Doelvis', 'en': 'Target fish', 'de': 'Zielfisch', 'fr': 'Poisson cible', 'es': 'Pez objetivo', 'pl': 'Ryba docelowa'},
  'flatfish': {'nl': 'Platvis', 'en': 'Flatfish', 'de': 'Plattfisch', 'fr': 'Poisson plat', 'es': 'Pez plano', 'pl': 'Płastuga'},
  'cod': {'nl': 'Kabeljauw', 'en': 'Cod', 'de': 'Dorsch', 'fr': 'Cabillaud', 'es': 'Bacalao', 'pl': 'Dorsz'},
  'bass': {'nl': 'Zeebaars', 'en': 'Bass', 'de': 'Wolfsbarsch', 'fr': 'Bar', 'es': 'Lubina', 'pl': 'Labraks'},
  'mackerel': {'nl': 'Makreel', 'en': 'Mackerel', 'de': 'Makrele', 'fr': 'Maquereau', 'es': 'Caballa', 'pl': 'Makrela'},
  'seaOut': {'nl': 'Aas + montage', 'en': 'Bait + rig', 'de': 'Köder + Montage', 'fr': 'Appât + montage', 'es': 'Cebo + montaje', 'pl': 'Przynęta + zestaw'},
  'tideTip': {'nl': 'Vis rond kentering: laatste uur opkomend / eerste uur afgaand water.', 'en': 'Fish around the turn: last hour of flood / first hour of ebb.', 'de': 'Um die Wende angeln: letzte Stunde Flut / erste Stunde Ebbe.', 'fr': "Pêchez autour de l'étale : dernière heure de flot / première heure de jusant.", 'es': 'Pesca en la parada: última hora de flujo / primera de reflujo.', 'pl': 'Łów przy zmianie: ostatnia godzina przypływu / pierwsza odpływu.'},
  'sea_flat': {'nl': 'Zeepier/mesheft · lepel- of wormmontage', 'en': 'Lugworm/razorfish · spoon or worm rig', 'de': 'Wattwurm/Messermuschel · Löffel- oder Wurmmontage', 'fr': 'Arénicole/couteau · montage cuiller ou ver', 'es': 'Gusana/navaja · montaje cuchara o gusano', 'pl': 'Nereida/małż · zestaw łyżkowy lub robak'},
  'sea_cod': {'nl': 'Zeepier + inktvis · plukmontage', 'en': 'Lugworm + squid · pulley rig', 'de': 'Wattwurm + Tintenfisch · Pulley-Rig', 'fr': 'Arénicole + calmar · montage pulley', 'es': 'Gusana + calamar · montaje pulley', 'pl': 'Nereida + kalmar · zestaw pulley'},
  'sea_bass': {'nl': 'Zandspiering/shad · drift of jig', 'en': 'Sandeel/shad · drift or jig', 'de': 'Sandaal/Shad · Drift oder Jig', 'fr': 'Lançon/shad · dérive ou jig', 'es': 'Lanzón/shad · deriva o jig', 'pl': 'Dobijak/shad · spław lub jig'},
  'sea_mack': {'nl': 'Makreelveren/blinker · snel inhalen', 'en': 'Mackerel feathers/spinner · fast retrieve', 'de': 'Makrelenfedern/Blinker · schnell einholen', 'fr': 'Plumes à maquereau/cuiller · récupération rapide', 'es': 'Plumas de caballa/cucharilla · recuperación rápida', 'pl': 'Pióra na makrelę/błystka · szybkie prowadzenie'},

  // ── Karper · Rig-kiezer (RIGT) ──
  'rig_title': {'nl': 'Karper · Rig-kiezer', 'en': 'Carp · Rig picker', 'de': 'Karpfen · Rig-Wähler', 'fr': 'Carpe · Sélecteur de montage', 'es': 'Carpa · Selector de montaje', 'pl': 'Karp · Dobór zestawu'},
  'rig_bottom': {'nl': 'Bodem', 'en': 'Bottom', 'de': 'Grund', 'fr': 'Fond', 'es': 'Fondo', 'pl': 'Dno'},
  'rig_hard': {'nl': 'Hard/schoon', 'en': 'Hard/clean', 'de': 'Hart/sauber', 'fr': 'Dur/propre', 'es': 'Duro/limpio', 'pl': 'Twarde/czyste'},
  'rig_soft': {'nl': 'Zacht/modder', 'en': 'Soft/mud', 'de': 'Weich/Schlamm', 'fr': 'Vase', 'es': 'Blando/fango', 'pl': 'Miękkie/muł'},
  'rig_weed': {'nl': 'Kruid', 'en': 'Weed', 'de': 'Kraut', 'fr': 'Herbiers', 'es': 'Vegetación', 'pl': 'Roślinność'},
  'rig_silt': {'nl': 'Slib', 'en': 'Silt', 'de': 'Schlick', 'fr': 'Limon', 'es': 'Limo', 'pl': 'Muł'},
  'rig_bait': {'nl': 'Aas', 'en': 'Bait', 'de': 'Köder', 'fr': 'Appât', 'es': 'Cebo', 'pl': 'Przynęta'},
  'rig_bBottom': {'nl': 'Bottom bait', 'en': 'Bottom bait', 'de': 'Bottom-Bait', 'fr': 'Bottom bait', 'es': 'Bottom bait', 'pl': 'Bottom bait'},
  'rig_bPop': {'nl': 'Pop-up', 'en': 'Pop-up', 'de': 'Pop-up', 'fr': 'Pop-up', 'es': 'Pop-up', 'pl': 'Pop-up'},
  'rig_bWaf': {'nl': 'Wafter', 'en': 'Wafter', 'de': 'Wafter', 'fr': 'Wafter', 'es': 'Wafter', 'pl': 'Wafter'},
  'rig_out': {'nl': 'Aanbevolen rig', 'en': 'Recommended rig', 'de': 'Empfohlenes Rig', 'fr': 'Montage conseillé', 'es': 'Montaje recomendado', 'pl': 'Zalecany zestaw'},
  'rig_r_chod': {'nl': 'Chod rig — presenteert het aas bóven kruid/slib', 'en': 'Chod rig — presents the bait above weed/silt', 'de': 'Chod-Rig — präsentiert über Kraut/Schlick', 'fr': 'Chod rig — présente au-dessus des herbiers/vase', 'es': 'Chod rig — presenta sobre la vegetación/limo', 'pl': 'Chod rig — prezentuje nad roślinnością/mułem'},
  'rig_r_ronnie': {'nl': 'Ronnie/spinner rig — 360° draai, ideaal voor pop-ups', 'en': 'Ronnie/spinner rig — 360° turn, ideal for pop-ups', 'de': 'Ronnie/Spinner-Rig — 360° Drehung, ideal für Pop-ups', 'fr': 'Ronnie/spinner rig — rotation 360°, idéal pop-up', 'es': 'Ronnie/spinner rig — giro 360°, ideal pop-up', 'pl': 'Ronnie/spinner rig — obrót 360°, idealny na pop-up'},
  'rig_r_blow': {'nl': 'Blowback rig — snelle inkering op schone bodem', 'en': 'Blowback rig — fast turning on clean bottoms', 'de': 'Blowback-Rig — schnelles Drehen auf sauberem Grund', 'fr': 'Blowback rig — pique vite sur fond propre', 'es': 'Blowback rig — clava rápido en fondo limpio', 'pl': 'Blowback rig — szybkie wbicie na czystym dnie'},
  'rig_r_hair': {'nl': 'Haarrig — de betrouwbare basis voor bottom baits', 'en': 'Hair rig — the reliable base for bottom baits', 'de': 'Haarrig — die zuverlässige Basis für Bottom-Baits', 'fr': 'Montage cheveu — la base fiable pour bottom baits', 'es': 'Montaje de pelo — la base fiable para bottom baits', 'pl': 'Włosowy — pewna podstawa dla bottom baits'},

  // ── Vliegvissen · Tippet-calculator (TIPT) ──
  'tip_title': {'nl': 'Vliegvissen · Tippet-calculator', 'en': 'Fly · Tippet calculator', 'de': 'Fliegen · Tippet-Rechner', 'fr': 'Mouche · Calculateur de pointe', 'es': 'Mosca · Calculadora de tippet', 'pl': 'Mucha · Kalkulator tippetu'},
  'tip_hook': {'nl': 'Haakmaat', 'en': 'Hook size', 'de': 'Hakengröße', 'fr': "Taille d'hameçon", 'es': 'Talla de anzuelo', 'pl': 'Rozmiar haka'},
  'tip_tippet': {'nl': 'Tippet', 'en': 'Tippet', 'de': 'Tippet', 'fr': 'Pointe', 'es': 'Tippet', 'pl': 'Tippet'},
  'tip_leader': {'nl': 'Leader-lengte', 'en': 'Leader length', 'de': 'Vorfachlänge', 'fr': 'Longueur du bas', 'es': 'Longitud del líder', 'pl': 'Długość leadera'},
  'tip_strain': {'nl': 'Ong. trekkracht', 'en': 'Approx. strength', 'de': 'Ca. Tragkraft', 'fr': 'Résistance approx.', 'es': 'Resistencia aprox.', 'pl': 'Ok. wytrzymałość'},
  'tip_tip': {'nl': 'Vuistregel: haakmaat ÷ 3 ≈ tippet-X. Dunner = stealthier, dikker = sterker.', 'en': 'Rule of thumb: hook size ÷ 3 ≈ tippet X. Thinner = stealthier, thicker = stronger.', 'de': 'Faustregel: Hakengröße ÷ 3 ≈ Tippet-X. Dünner = unauffälliger, dicker = stärker.', 'fr': 'Règle : taille ÷ 3 ≈ pointe X. Plus fin = discret, plus épais = solide.', 'es': 'Regla: talla ÷ 3 ≈ tippet X. Más fino = sigiloso, más grueso = fuerte.', 'pl': 'Zasada: rozmiar ÷ 3 ≈ tippet X. Cieńszy = dyskretny, grubszy = mocniejszy.'},

  // ── Populair bij leden (POPT) ──
  'pop_title': {'nl': 'Populair bij leden', 'en': 'Popular with members', 'de': 'Beliebt bei Mitgliedern', 'fr': 'Populaire chez les membres', 'es': 'Popular entre los socios', 'pl': 'Popularne wśród członków'},
  'pop_bait': {'nl': 'Top aas / kunstaas', 'en': 'Top bait / lure', 'de': 'Top Köder', 'fr': 'Top appât / leurre', 'es': 'Top cebo / señuelo', 'pl': 'Top przynęta'},
  'pop_tech': {'nl': 'Top techniek', 'en': 'Top technique', 'de': 'Top Technik', 'fr': 'Top technique', 'es': 'Top técnica', 'pl': 'Top technika'},
  'pop_species': {'nl': 'Top soort', 'en': 'Top species', 'de': 'Top Art', 'fr': 'Top espèce', 'es': 'Top especie', 'pl': 'Top gatunek'},
  'pop_based': {'nl': 'op basis van', 'en': 'based on', 'de': 'basierend auf', 'fr': 'basé sur', 'es': 'basado en', 'pl': 'na podstawie'},
  'pop_catches': {'nl': 'openbare community-vangsten', 'en': 'public community catches', 'de': 'öffentliche Community-Fänge', 'fr': 'prises publiques de la communauté', 'es': 'capturas públicas de la comunidad', 'pl': 'publicznych połowów społeczności'},
  'pop_none': {'nl': 'Nog te weinig ledendata voor deze stijl — deel je vangsten openbaar!', 'en': 'Not enough member data yet for this style — share your catches publicly!', 'de': 'Noch zu wenig Mitgliederdaten für diesen Stil — teile deine Fänge öffentlich!', 'fr': 'Pas assez de données membres pour ce style — partagez vos prises publiquement !', 'es': 'Aún faltan datos de socios para este estilo — ¡comparte tus capturas!', 'pl': 'Za mało danych członków dla tego stylu — dziel się połowami publicznie!'},

  // ── Kennis & tips (Knowledge label + video-knop) ──
  'know_label': {'nl': 'Kennis & tips', 'en': 'Knowledge & tips', 'de': 'Wissen & Tipps', 'fr': 'Savoir & astuces', 'es': 'Conocimiento y consejos', 'pl': 'Wiedza i porady'},
  'know_video': {'nl': 'Video-tutorials', 'en': 'Video tutorials', 'de': 'Video-Tutorials', 'fr': 'Tutos vidéo', 'es': 'Tutoriales en vídeo', 'pl': 'Poradniki wideo'},
};

// ── Checklists (karper + meerval) → { disc → { locale → items } } ────────────
const Map<String, Map<String, List<String>>> kVttChecklist = {
  'carp': {
    'nl': ['Bivvy + slaapzak', 'Beetmelders', 'Onthaakmat + weegzak', 'Landingsnet', 'Voer + PVA', 'Hoofdlamp', 'Warme kleding', 'Eten & drinken'],
    'en': ['Bivvy + sleeping bag', 'Bite alarms', 'Unhooking mat + sling', 'Landing net', 'Bait + PVA', 'Head torch', 'Warm clothing', 'Food & drink'],
    'de': ['Bivvy + Schlafsack', 'Bissanzeiger', 'Abhakmatte + Wiegesack', 'Kescher', 'Futter + PVA', 'Kopflampe', 'Warme Kleidung', 'Essen & Trinken'],
    'fr': ['Biwy + duvet', 'Détecteurs', 'Tapis + sac de pesée', 'Épuisette', 'Amorce + PVA', 'Lampe frontale', 'Vêtements chauds', 'Nourriture & boisson'],
    'es': ['Bivvy + saco', 'Avisadores', 'Alfombrilla + saco de pesaje', 'Sacadera', 'Cebo + PVA', 'Frontal', 'Ropa de abrigo', 'Comida y bebida'],
    'pl': ['Bivvy + śpiwór', 'Sygnalizatory', 'Mata + worek do ważenia', 'Podbierak', 'Zanęta + PVA', 'Latarka czołowa', 'Ciepła odzież', 'Jedzenie i picie'],
  },
  'catfish': {
    'nl': ['Zware hengel + molen', 'Onthaakmat XL', 'Handschoenen', 'Krachtige lijn/leader', 'Boei/marker', 'Hoofdlamp', 'Weeghaak + zak'],
    'en': ['Heavy rod + reel', 'XL unhooking mat', 'Gloves', 'Strong line/leader', 'Marker buoy', 'Head torch', 'Weigh scale + sling'],
    'de': ['Schwere Rute + Rolle', 'XL-Abhakmatte', 'Handschuhe', 'Starke Schnur/Vorfach', 'Markerboje', 'Kopflampe', 'Waage + Sack'],
    'fr': ['Canne + moulinet puissants', 'Tapis XL', 'Gants', 'Ligne/bas de ligne solide', 'Bouée marqueur', 'Lampe frontale', 'Peson + sac'],
    'es': ['Caña + carrete potentes', 'Alfombrilla XL', 'Guantes', 'Línea/líder fuerte', 'Boya marcadora', 'Frontal', 'Pesola + saco'],
    'pl': ['Mocna wędka + kołowrotek', 'Mata XL', 'Rękawice', 'Mocna żyłka/przypon', 'Boja markerowa', 'Latarka czołowa', 'Waga + worek'],
  },
};

// ── Tippet-trekkracht (haakmaat-X → sterkte) ─────────────────────────────────
const Map<int, String> kTippetLb = {3: '~3,8 kg', 4: '~2,7 kg', 5: '~2,2 kg', 6: '~1,6 kg', 7: '~1,1 kg', 8: '~0,8 kg'};

// ── Kennis-media per kennis-item (index-uitgelijnd, taal-onafhankelijk) ──────
// {'yt': id} = embed; {'q': zoekopdracht} = val-terug naar YouTube-zoekknop.
const Map<String, List<Map<String, String>>> kVttKnowMedia = {
  'carp': [{'yt': 'gcUDaLoMPzs'}, {'q': 'blowback rig carp tie tutorial'}, {'q': 'chod rig carp tie tutorial'}, {'yt': '6f-VetQP-Ro'}, {'yt': 'x5M4EpdQUKE'}, {'q': 'carp bait water temperature strategy'}],
  'coarse': [{'q': 'pole vs feeder fishing explained'}, {'q': 'coarse fishing feeding little and often'}, {'q': 'coarse fishing hooklength hook size'}],
  'feeder': [{'q': 'feeder types open end method cage window'}, {'q': 'feeder fishing hooklength length'}, {'q': 'feeder fishing clip up cast same spot'}],
  'predator': [{'q': 'predator lure types shad jerkbait crankbait'}, {'q': 'pike zander perch closed season rules'}, {'q': 'stinger trailing hook predator lure'}],
  'street': [{'q': 'ultralight streetfishing setup'}, {'q': 'streetfishing urban perch spots'}, {'q': 'sight fishing clear water lure'}],
  'catfish': [{'q': 'catfish fishing methods clonking'}, {'q': 'catfish tackle rig setup'}, {'q': 'catfish night fishing bait'}],
  'fly': [{'q': 'fly fishing line weight explained'}, {'q': 'dry fly nymph streamer difference'}, {'q': 'fly fishing drag free drift mending'}],
  'trout': [{'q': 'trout pond vs stream fishing tips'}, {'q': 'trout spinner spoon fishing'}, {'q': 'trout water temperature fishing'}],
  'sea': [{'q': 'sea fishing best tide times'}, {'q': 'sea fishing rigs paternoster how to tie'}, {'q': 'fish minimum size limits regulations'}],
};

// ── Kennis & tips per vistijl → { locale → { disc → items[{t,b}] } } ──────────
const Map<String, Map<String, List<Map<String, String>>>> kVttKnow = {
  'nl': {
    'carp': [
      {'t': '🪝 Haarrig', 'b': 'Aas aan een haartje náást de haak. De karper zuigt het aas op, de haak draait in de onderlip. De basis onder bijna elke karpermontage.'},
      {'t': '🪝 Blowback rig', 'b': 'Een kraaltje laat de haak vrij bewegen — draait sneller in bij korte, voorzichtige aanbeten. Sterk op harde/propere bodem.'},
      {'t': '🪝 Chod rig', 'b': 'Korte, stijve rig die het aas bóven rommel, blad of slib presenteert. Ideaal op oneffen of vervuilde bodem.'},
      {'t': '🪝 Ronnie / spinner rig', 'b': 'Haak draait 360° via een wartel — extreem vinnig aanhaken. Populair met een pop-up net boven de bodem.'},
      {'t': '🎣 Knotless knot', 'b': 'De knoop die het haartje vormt en de haaklengte + “kick” van de haak bepaalt. Hou de haar kort: aas net achter de haakbocht.'},
      {'t': '🌽 Voer op activiteit', 'b': 'Bij koud water (<10°) minder en fijner voeren; bij warm water mag je gericht een bed leggen. Match je aas aan het voer.'},
    ],
    'coarse': [
      {'t': '🎣 Vaste stok vs feeder', 'b': 'Vaste stok = precisie op korte afstand en fijne vis. Feeder = verder werpen en gericht bijvoeren. Kies op afstand en wind.'},
      {'t': '🍚 Voerritme', 'b': 'Klein en vaak bijvoeren houdt de school actief op je stek. Stopt de beet: verklein je aas of voer minder.'},
      {'t': '⚖️ Onderlijn & haak', 'b': 'Fijner vissen (dunnere onderlijn, kleinere haak) geeft meer beten bij heldere, koude of beviste wateren.'},
    ],
    'feeder': [
      {'t': '🧺 Korf-typen', 'b': 'Open-end = rivier/stroming (voer spoelt uit), method = dichtbij en snel op de aas, cage = fijn voer, window = gedoseerd. Kies op stroming en afstand.'},
      {'t': '📏 Onderlijn-lengte', 'b': 'Korter (20–40 cm) bij actieve vis, langer (60–100 cm) bij voorzichtige/heldere condities.'},
      {'t': '🕐 Klok-methode', 'b': 'Merk je werp-afstand (clip) en richt op een vast punt aan de overkant — zo landt elke worp op dezelfde stek.'},
    ],
    'predator': [
      {'t': '🎣 Kunstaas-typen', 'b': 'Shad = allround, jerkbait = traag/koud, crankbait = snel water afzoeken, spinnerbait = troebel, topwater = warm & ondiep.'},
      {'t': '📅 Gesloten tijd (NL)', 'b': 'Snoek: 1 maart t/m laatste zaterdag mei. Snoekbaars & baars: 1 april t/m laatste zaterdag mei. Check je regio — verschilt per land/water.'},
      {'t': '🪝 Stinger / dreg', 'b': 'Een extra achterhaak (stinger) vangt korte aanbeten en missers — vooral nuttig in koud water als de vis traag pakt.'},
    ],
    'street': [
      {'t': '🎣 Ultralight-setup', 'b': 'Jigkoppen 0,5–3 g, dunne gevlochten lijn (0,06–0,10 mm) + fluorocarbon voor, een lichte L-/UL-hengel. Klein shad of nano.'},
      {'t': '🏙️ Stads-stekken', 'b': 'Vis sluizen, bruggen, instroom, hoeken en langs kademuren — daar staat het roofvisje op de loer. Blijf mobiel.'},
      {'t': '👁️ Zicht-vissen', 'b': 'In helder stadswater zie je de vis vaak. Werp voorbij en haal langs — niet er bovenop.'},
    ],
    'catfish': [
      {'t': '🎣 Methodes', 'b': 'Afdrijven (met de stroom over kuilen), peiler/pose (vaste stek bij structuur), klopstok (verticaal boven diep), of vanaf de kant naar overhangende oevers.'},
      {'t': '💪 Materiaal', 'b': 'Sterke hoofdlijn/leader, grote haken, degelijke molen en een onthaakmat XL. Meerval is krachtig — onderschat je materiaal niet.'},
      {'t': '🌡️ Timing', 'b': 'Warme zomernachten zijn top. Aas met veel geur (inktvis, paling, wormbundel) werkt sterk in donker/troebel water.'},
    ],
    'fly': [
      {'t': '🎣 Lijnklasse', 'b': '#3–5 voor beek/forel, #6–7 allround, #8+ voor roofvis en zee. Zwaardere klasse = grotere vliegen en meer wind aankunnen.'},
      {'t': '🪰 Vlieg-typen', 'b': 'Droge vlieg (oppervlak), nimf (onder water), streamer (imitatie visje, roofvis), natte vlieg (net onder de film).'},
      {'t': '🌊 Drift', 'b': 'In stromend water: laat de vlieg natuurlijk meedrijven zonder sleep (“drag”). Mend je lijn om een dode drift te houden.'},
    ],
    'trout': [
      {'t': '🎣 Put vs beek', 'b': 'Forelput = uitgezette, actieve vis — powerbait, deeg of spinner werkt. Beek = natuurlijke, schuwe forel — fijn en onopvallend vissen.'},
      {'t': '🥄 Aas & spinner', 'b': 'Kleine spinner/spoon bij koud water langzaam; sneller inhalen als het water opwarmt. Varieer kleur bij troebelheid.'},
      {'t': '🌡️ Temperatuur', 'b': 'Forel houdt van koeler, zuurstofrijk water. Vroeg en laat op de dag en na regen zijn topmomenten.'},
    ],
    'sea': [
      {'t': '🌙 Getij', 'b': 'Rond de kentering (laatste uur opkomend / eerste uur afgaand) is de vis het actiefst. Plan je sessie op het tij, niet op de klok.'},
      {'t': '🧰 Montages', 'b': 'Paternoster = bodemvis (platvis/kabeljauw), lepelmontage = platvis, drijvend/veren = makreel & zeebaars in de bovenlaag.'},
      {'t': '📏 Minimaten', 'b': 'Hou je aan minimaten en gesloten tijden per soort en regio — die verschillen per land. Zet ondermaatse vis voorzichtig terug.'},
    ],
  },
  'en': {
    'carp': [
      {'t': '🪝 Hair rig', 'b': 'Bait on a hair next to the hook. The carp sucks in the bait, the hook turns into the bottom lip. The base of nearly every carp rig.'},
      {'t': '🪝 Blowback rig', 'b': 'A bead lets the hook move freely — turns quicker on short, cautious takes. Strong on hard, clean bottoms.'},
      {'t': '🪝 Chod rig', 'b': 'A short, stiff rig that presents the bait above debris, leaves or silt. Ideal on uneven or dirty bottoms.'},
      {'t': '🪝 Ronnie / spinner rig', 'b': 'Hook rotates 360° on a swivel — extremely sharp hooking. Popular with a pop-up just off the bottom.'},
      {'t': '🎣 Knotless knot', 'b': 'The knot that forms the hair and sets hook length + “kick”. Keep the hair short: bait just behind the bend.'},
      {'t': '🌽 Feed to activity', 'b': 'In cold water (<10°) feed less and finer; in warm water you can lay a bed. Match your hookbait to the feed.'},
    ],
    'coarse': [
      {'t': '🎣 Pole vs feeder', 'b': 'Pole = precision at close range for shy fish. Feeder = casting further and targeted feeding. Choose on distance and wind.'},
      {'t': '🍚 Feeding rhythm', 'b': 'Little and often keeps the shoal active on your swim. Bites stop: downsize your bait or feed less.'},
      {'t': '⚖️ Hooklength & hook', 'b': 'Finer tackle (thinner hooklength, smaller hook) gets more bites on clear, cold or pressured waters.'},
    ],
    'feeder': [
      {'t': '🧺 Feeder types', 'b': 'Open-end = river/flow, method = close and fast to the bait, cage = fine feed, window = dosed. Pick on flow and distance.'},
      {'t': '📏 Hooklength', 'b': 'Shorter (20–40 cm) for active fish, longer (60–100 cm) in cautious/clear conditions.'},
      {'t': '🕐 Clip method', 'b': 'Clip your casting distance and aim at a fixed far-bank marker — every cast lands on the same spot.'},
    ],
    'predator': [
      {'t': '🎣 Lure types', 'b': 'Shad = allround, jerkbait = slow/cold, crankbait = cover water fast, spinnerbait = murky, topwater = warm & shallow.'},
      {'t': '📅 Closed season (NL)', 'b': 'Pike: 1 Mar–last Sat of May. Zander & perch: 1 Apr–last Sat of May. Check your region — it differs per country/water.'},
      {'t': '🪝 Stinger hook', 'b': 'An extra trailing hook catches short takes and misses — especially useful in cold water when fish nip.'},
    ],
    'street': [
      {'t': '🎣 Ultralight setup', 'b': 'Jig heads 0.5–3 g, thin braid (0.06–0.10 mm) + fluorocarbon leader, a light L/UL rod. Small shads or nano lures.'},
      {'t': '🏙️ Urban spots', 'b': 'Fish locks, bridges, inflows, corners and along quay walls — that’s where predators lurk. Stay mobile.'},
      {'t': '👁️ Sight fishing', 'b': 'In clear urban water you often see the fish. Cast past and retrieve alongside — not right on top.'},
    ],
    'catfish': [
      {'t': '🎣 Methods', 'b': 'Drifting (with the flow over holes), static/float (fixed spot near structure), clonking (vertical over deep), or from the bank to overhanging edges.'},
      {'t': '💪 Tackle', 'b': 'Strong mainline/leader, big hooks, a solid reel and an XL unhooking mat. Catfish are powerful — don’t underestimate your gear.'},
      {'t': '🌡️ Timing', 'b': 'Warm summer nights are prime. Smelly baits (squid, eel, worm bundles) work strongly in dark/murky water.'},
    ],
    'fly': [
      {'t': '🎣 Line weight', 'b': '#3–5 for streams/trout, #6–7 allround, #8+ for predators and sea. Heavier line = bigger flies and more wind.'},
      {'t': '🪰 Fly types', 'b': 'Dry (surface), nymph (subsurface), streamer (baitfish imitation, predators), wet (just under the film).'},
      {'t': '🌊 Drift', 'b': 'In current, let the fly drift naturally without drag. Mend your line to keep a dead drift.'},
    ],
    'trout': [
      {'t': '🎣 Pond vs stream', 'b': 'Trout pond = stocked, active fish — powerbait, dough or spinner. Stream = natural, wary trout — fish fine and subtle.'},
      {'t': '🥄 Bait & spinner', 'b': 'Small spinner/spoon slow in cold water; retrieve faster as it warms. Vary colour with clarity.'},
      {'t': '🌡️ Temperature', 'b': 'Trout like cooler, oxygen-rich water. Early, late and after rain are prime moments.'},
    ],
    'sea': [
      {'t': '🌙 Tide', 'b': 'Around the turn (last hour of flood / first of ebb) the fish are most active. Plan on the tide, not the clock.'},
      {'t': '🧰 Rigs', 'b': 'Paternoster = bottom fish (flatfish/cod), spoon rig = flatfish, floating/feathers = mackerel & bass in the upper layer.'},
      {'t': '📏 Minimum sizes', 'b': 'Respect minimum sizes and closed seasons per species and region — they differ by country. Return undersized fish gently.'},
    ],
  },
  'de': {
    'carp': [
      {'t': '🪝 Haarrig', 'b': 'Köder an einem Haar neben dem Haken. Der Karpfen saugt den Köder ein, der Haken dreht in die Unterlippe. Basis fast jeder Karpfenmontage.'},
      {'t': '🪝 Blowback-Rig', 'b': 'Eine Perle lässt den Haken frei laufen — dreht schneller bei kurzen, vorsichtigen Bissen. Stark auf hartem, sauberem Grund.'},
      {'t': '🪝 Chod-Rig', 'b': 'Kurzes, steifes Rig, das den Köder über Kraut, Laub oder Schlamm präsentiert. Ideal auf unebenem Grund.'},
      {'t': '🪝 Ronnie / Spinner-Rig', 'b': 'Haken dreht 360° am Wirbel — extrem scharfes Haken. Beliebt mit Pop-up knapp über Grund.'},
      {'t': '🎣 Knotenloser Knoten', 'b': 'Der Knoten, der das Haar bildet und Hakenlänge + „Kick“ bestimmt. Haar kurz halten: Köder direkt hinter dem Hakenbogen.'},
      {'t': '🌽 Füttern nach Aktivität', 'b': 'Bei kaltem Wasser (<10°) weniger und feiner füttern; bei warmem Wasser ein Bett anlegen. Köder ans Futter anpassen.'},
    ],
    'coarse': [
      {'t': '🎣 Stippe vs Feeder', 'b': 'Stippe = Präzision auf kurze Distanz für scheue Fische. Feeder = weiter werfen und gezielt füttern. Nach Distanz und Wind wählen.'},
      {'t': '🍚 Fütterrhythmus', 'b': 'Wenig und oft hält den Schwarm aktiv. Bisse hören auf: Köder verkleinern oder weniger füttern.'},
      {'t': '⚖️ Vorfach & Haken', 'b': 'Feineres Gerät (dünneres Vorfach, kleinerer Haken) bringt mehr Bisse an klaren, kalten oder beangelten Gewässern.'},
    ],
    'feeder': [
      {'t': '🧺 Korb-Typen', 'b': 'Open-End = Fluss/Strömung, Method = nah und schnell am Köder, Cage = feines Futter, Window = dosiert. Nach Strömung und Distanz.'},
      {'t': '📏 Vorfachlänge', 'b': 'Kürzer (20–40 cm) bei aktiven Fischen, länger (60–100 cm) bei vorsichtigen/klaren Bedingungen.'},
      {'t': '🕐 Clip-Methode', 'b': 'Wurfweite clippen und auf einen festen Punkt am Gegenufer zielen — jeder Wurf landet an derselben Stelle.'},
    ],
    'predator': [
      {'t': '🎣 Kunstköder-Typen', 'b': 'Gummifisch = Allround, Jerkbait = langsam/kalt, Crankbait = schnell absuchen, Spinnerbait = trüb, Topwater = warm & flach.'},
      {'t': '📅 Schonzeit (NL)', 'b': 'Hecht: 1. März–letzter Samstag Mai. Zander & Barsch: 1. April–letzter Samstag Mai. Region prüfen — je Land/Gewässer anders.'},
      {'t': '🪝 Stinger-Haken', 'b': 'Ein zusätzlicher Nachläufer-Haken fängt kurze Bisse und Fehlbisse — besonders im kalten Wasser nützlich.'},
    ],
    'street': [
      {'t': '🎣 Ultralight-Setup', 'b': 'Jigköpfe 0,5–3 g, dünne geflochtene Schnur (0,06–0,10 mm) + Fluorocarbon, leichte L/UL-Rute. Kleine Gummifische.'},
      {'t': '🏙️ Stadt-Spots', 'b': 'Angle Schleusen, Brücken, Einläufe, Ecken und Kaimauern — dort lauern die Räuber. Bleib mobil.'},
      {'t': '👁️ Sichtangeln', 'b': 'In klarem Stadtwasser siehst du den Fisch oft. Wirf vorbei und führe daneben — nicht direkt drauf.'},
    ],
    'catfish': [
      {'t': '🎣 Methoden', 'b': 'Abtreiben (mit der Strömung über Löcher), stationär/Pose (fester Platz an Struktur), Klopfen (vertikal über tief) oder vom Ufer an Überhänge.'},
      {'t': '💪 Gerät', 'b': 'Starke Hauptschnur/Vorfach, große Haken, solide Rolle und XL-Abhakmatte. Welse sind stark — unterschätze dein Gerät nicht.'},
      {'t': '🌡️ Timing', 'b': 'Warme Sommernächte sind top. Geruchsintensive Köder (Tintenfisch, Aal, Wurmbündel) wirken in dunklem/trübem Wasser.'},
    ],
    'fly': [
      {'t': '🎣 Schnurklasse', 'b': '#3–5 für Bach/Forelle, #6–7 Allround, #8+ für Raubfisch und Meer. Schwerere Klasse = größere Fliegen und mehr Wind.'},
      {'t': '🪰 Fliegen-Typen', 'b': 'Trockenfliege (Oberfläche), Nymphe (unter Wasser), Streamer (Fischimitat, Raubfisch), Nassfliege (knapp unter der Oberfläche).'},
      {'t': '🌊 Drift', 'b': 'In der Strömung die Fliege natürlich treiben lassen, ohne Schleifen. Mende die Schnur für eine tote Drift.'},
    ],
    'trout': [
      {'t': '🎣 Teich vs Bach', 'b': 'Forellenteich = besetzte, aktive Fische — Powerbait, Teig oder Spinner. Bach = natürliche, scheue Forelle — fein und unauffällig.'},
      {'t': '🥄 Köder & Spinner', 'b': 'Kleiner Spinner/Blinker langsam bei kaltem Wasser; schneller einholen, wenn es wärmer wird. Farbe nach Trübung variieren.'},
      {'t': '🌡️ Temperatur', 'b': 'Forellen mögen kühleres, sauerstoffreiches Wasser. Früh, spät und nach Regen sind Topmomente.'},
    ],
    'sea': [
      {'t': '🌙 Gezeiten', 'b': 'Um die Kenterung (letzte Stunde Flut / erste Ebbe) sind die Fische am aktivsten. Nach der Tide planen, nicht nach der Uhr.'},
      {'t': '🧰 Montagen', 'b': 'Paternoster = Grundfisch (Plattfisch/Dorsch), Löffelmontage = Plattfisch, treibend/Federn = Makrele & Wolfsbarsch oben.'},
      {'t': '📏 Mindestmaße', 'b': 'Halte Mindestmaße und Schonzeiten je Art und Region ein — je Land verschieden. Untermaßige Fische schonend zurücksetzen.'},
    ],
  },
  'fr': {
    'carp': [
      {'t': '🪝 Montage cheveu', 'b': "Appât sur un cheveu à côté de l'hameçon. La carpe aspire l'appât, l'hameçon pique la lèvre inférieure. La base de presque tous les montages."},
      {'t': '🪝 Blowback rig', 'b': "Une perle laisse l'hameçon libre — pique plus vite sur les touches courtes. Efficace sur fond dur et propre."},
      {'t': '🪝 Chod rig', 'b': "Montage court et rigide qui présente l'appât au-dessus des débris ou de la vase. Idéal sur fond inégal."},
      {'t': '🪝 Ronnie / spinner rig', 'b': 'Hameçon qui tourne à 360° sur un émerillon — ferrage très net. Populaire avec une pop-up près du fond.'},
      {'t': '🎣 Nœud sans nœud', 'b': 'Le nœud qui forme le cheveu et règle la longueur + le « kick ». Cheveu court : appât juste derrière la courbure.'},
      {'t': "🌽 Nourrir selon l'activité", 'b': 'Eau froide (<10°) : nourrir peu et fin ; eau chaude : faire un tapis. Accordez l’esche à l’amorce.'},
    ],
    'coarse': [
      {'t': '🎣 Canne vs feeder', 'b': 'Canne = précision à courte distance pour poissons méfiants. Feeder = lancer loin et amorcer ciblé. Selon distance et vent.'},
      {'t': "🍚 Rythme d'amorçage", 'b': 'Peu et souvent maintient le banc actif. Les touches cessent : réduisez l’esche ou amorcez moins.'},
      {'t': '⚖️ Bas de ligne & hameçon', 'b': 'Matériel plus fin = plus de touches en eau claire, froide ou pêchée.'},
    ],
    'feeder': [
      {'t': '🧺 Types de cage', 'b': 'Open-end = rivière/courant, method = près et vite sur l’esche, cage = amorce fine, window = dosé. Selon courant et distance.'},
      {'t': '📏 Longueur du bas de ligne', 'b': 'Plus court (20–40 cm) pour poissons actifs, plus long (60–100 cm) en conditions prudentes/claires.'},
      {'t': '🕐 Méthode du clip', 'b': 'Clipez la distance et visez un repère fixe en face — chaque lancer tombe au même endroit.'},
    ],
    'predator': [
      {'t': '🎣 Types de leurres', 'b': 'Shad = polyvalent, jerkbait = lent/froid, crankbait = prospecter vite, spinnerbait = eau trouble, topwater = chaud & peu profond.'},
      {'t': '📅 Fermeture (NL)', 'b': 'Brochet : 1 mars–dernier samedi de mai. Sandre & perche : 1 avril–dernier samedi de mai. Vérifiez votre région.'},
      {'t': '🪝 Hameçon stinger', 'b': 'Un hameçon arrière supplémentaire capture les touches courtes et les ratés — surtout utile en eau froide.'},
    ],
    'street': [
      {'t': '🎣 Setup ultraléger', 'b': 'Têtes plombées 0,5–3 g, tresse fine (0,06–0,10 mm) + fluorocarbone, canne L/UL légère. Petits shads.'},
      {'t': '🏙️ Spots urbains', 'b': 'Pêchez écluses, ponts, arrivées d’eau, angles et le long des quais — les carnassiers y rôdent. Restez mobile.'},
      {'t': '👁️ Pêche à vue', 'b': 'En eau claire urbaine, on voit souvent le poisson. Lancez au-delà et ramenez le long — pas dessus.'},
    ],
    'catfish': [
      {'t': '🎣 Méthodes', 'b': 'Dérive (avec le courant sur les fosses), poste fixe/flotteur (près des structures), clonk (vertical au-dessus du profond) ou du bord.'},
      {'t': '💪 Matériel', 'b': 'Ligne/bas de ligne solides, gros hameçons, moulinet robuste et tapis XL. Le silure est puissant — ne sous-estimez pas.'},
      {'t': '🌡️ Timing', 'b': 'Les nuits chaudes d’été sont idéales. Appâts odorants (calmar, anguille, bouquets de vers) en eau sombre/trouble.'},
    ],
    'fly': [
      {'t': '🎣 Classe de soie', 'b': '#3–5 pour ruisseau/truite, #6–7 polyvalent, #8+ pour carnassiers et mer. Plus lourd = mouches plus grosses et plus de vent.'},
      {'t': '🪰 Types de mouches', 'b': 'Sèche (surface), nymphe (sous l’eau), streamer (imitation de poisson, carnassiers), noyée (juste sous la pellicule).'},
      {'t': '🌊 Dérive', 'b': 'En courant, laissez dériver naturellement sans « drag ». Mendez la soie pour une dérive morte.'},
    ],
    'trout': [
      {'t': '🎣 Étang vs ruisseau', 'b': 'Étang = truites lâchées, actives — powerbait, pâte ou cuiller. Ruisseau = truite sauvage, méfiante — pêche fine et discrète.'},
      {'t': '🥄 Appât & cuiller', 'b': 'Petite cuiller lente en eau froide ; ramenez plus vite quand ça se réchauffe. Variez la couleur selon la turbidité.'},
      {'t': '🌡️ Température', 'b': 'La truite aime l’eau fraîche et oxygénée. Tôt, tard et après la pluie sont les meilleurs moments.'},
    ],
    'sea': [
      {'t': '🌙 Marée', 'b': "Autour de l'étale (dernière heure de flot / première de jusant), le poisson est le plus actif. Planifiez sur la marée."},
      {'t': '🧰 Montages', 'b': 'Paternoster = poisson de fond (plat/cabillaud), montage cuiller = poisson plat, flottant/plumes = maquereau & bar en surface.'},
      {'t': '📏 Tailles minimales', 'b': 'Respectez tailles minimales et fermetures par espèce et région — variables selon le pays. Relâchez délicatement.'},
    ],
  },
  'es': {
    'carp': [
      {'t': '🪝 Montaje de pelo', 'b': 'Cebo en un pelo junto al anzuelo. La carpa aspira el cebo, el anzuelo gira al labio inferior. La base de casi todos los montajes.'},
      {'t': '🪝 Blowback rig', 'b': 'Una cuenta deja el anzuelo libre — clava más rápido en picadas cortas. Fuerte en fondos duros y limpios.'},
      {'t': '🪝 Chod rig', 'b': 'Montaje corto y rígido que presenta el cebo sobre restos o limo. Ideal en fondos irregulares.'},
      {'t': '🪝 Ronnie / spinner rig', 'b': 'El anzuelo gira 360° en un emerillón — clavada muy afilada. Popular con pop-up cerca del fondo.'},
      {'t': '🎣 Nudo sin nudo', 'b': 'El nudo que forma el pelo y fija la longitud y el “kick”. Pelo corto: cebo justo tras la curva.'},
      {'t': '🌽 Cebar según actividad', 'b': 'Agua fría (<10°): cebar poco y fino; agua cálida: hacer una cama. Ajusta el cebo al engodo.'},
    ],
    'coarse': [
      {'t': '🎣 Pértiga vs feeder', 'b': 'Pértiga = precisión a corta distancia para peces esquivos. Feeder = lanzar lejos y cebar dirigido. Según distancia y viento.'},
      {'t': '🍚 Ritmo de cebado', 'b': 'Poco y a menudo mantiene activo el banco. Cesan las picadas: reduce el cebo o ceba menos.'},
      {'t': '⚖️ Bajo de línea y anzuelo', 'b': 'Aparejo más fino = más picadas en aguas claras, frías o presionadas.'},
    ],
    'feeder': [
      {'t': '🧺 Tipos de cesta', 'b': 'Open-end = río/corriente, method = cerca y rápido al cebo, cage = engodo fino, window = dosificado. Según corriente y distancia.'},
      {'t': '📏 Longitud del bajo', 'b': 'Más corto (20–40 cm) con peces activos, más largo (60–100 cm) en condiciones prudentes/claras.'},
      {'t': '🕐 Método del clip', 'b': 'Clipa la distancia y apunta a un punto fijo enfrente — cada lance cae en el mismo sitio.'},
    ],
    'predator': [
      {'t': '🎣 Tipos de señuelo', 'b': 'Shad = polivalente, jerkbait = lento/frío, crankbait = rastrear rápido, spinnerbait = turbia, topwater = cálido y somero.'},
      {'t': '📅 Veda (NL)', 'b': 'Lucio: 1 mar–último sábado de mayo. Lucioperca y perca: 1 abr–último sábado de mayo. Consulta tu región.'},
      {'t': '🪝 Anzuelo stinger', 'b': 'Un anzuelo trasero extra atrapa picadas cortas y fallos — útil en agua fría cuando el pez muerde flojo.'},
    ],
    'street': [
      {'t': '🎣 Equipo ultraligero', 'b': 'Cabezas plomadas 0,5–3 g, trenzado fino (0,06–0,10 mm) + fluorocarbono, caña L/UL ligera. Shads pequeños.'},
      {'t': '🏙️ Puestos urbanos', 'b': 'Pesca esclusas, puentes, entradas de agua, esquinas y muros — ahí acechan los depredadores. Sé móvil.'},
      {'t': '👁️ Pesca a vista', 'b': 'En agua urbana clara sueles ver el pez. Lanza más allá y recupera al lado — no encima.'},
    ],
    'catfish': [
      {'t': '🎣 Métodos', 'b': 'A la deriva (con la corriente sobre fosas), fijo/flotador (junto a estructura), clonk (vertical sobre lo hondo) o desde la orilla.'},
      {'t': '💪 Equipo', 'b': 'Línea/líder fuertes, anzuelos grandes, carrete robusto y alfombrilla XL. El siluro es potente — no lo subestimes.'},
      {'t': '🌡️ Timing', 'b': 'Las noches cálidas de verano son ideales. Cebos olorosos (calamar, anguila, manojos de lombriz) en agua oscura/turbia.'},
    ],
    'fly': [
      {'t': '🎣 Clase de línea', 'b': '#3–5 para arroyo/trucha, #6–7 polivalente, #8+ para depredadores y mar. Más pesada = moscas grandes y más viento.'},
      {'t': '🪰 Tipos de mosca', 'b': 'Seca (superficie), ninfa (bajo el agua), streamer (imitación de pez, depredadores), ahogada (bajo la película).'},
      {'t': '🌊 Deriva', 'b': 'En corriente, deja derivar natural sin “drag”. Mendea la línea para una deriva muerta.'},
    ],
    'trout': [
      {'t': '🎣 Coto vs arroyo', 'b': 'Coto = truchas sembradas, activas — powerbait, masa o cucharilla. Arroyo = trucha salvaje, recelosa — pesca fina y discreta.'},
      {'t': '🥄 Cebo y cucharilla', 'b': 'Cucharilla pequeña lenta en agua fría; recupera más rápido al calentar. Varía el color según turbidez.'},
      {'t': '🌡️ Temperatura', 'b': 'La trucha prefiere agua fresca y oxigenada. Temprano, tarde y tras la lluvia son los mejores momentos.'},
    ],
    'sea': [
      {'t': '🌙 Marea', 'b': 'En la parada (última hora de flujo / primera de reflujo) el pez está más activo. Planifica según la marea.'},
      {'t': '🧰 Montajes', 'b': 'Paternoster = pez de fondo (plano/bacalao), montaje cuchara = pez plano, flotante/plumas = caballa y lubina en superficie.'},
      {'t': '📏 Tallas mínimas', 'b': 'Respeta tallas mínimas y vedas por especie y región — varían por país. Devuelve con cuidado los ejemplares pequeños.'},
    ],
  },
  'pl': {
    'carp': [
      {'t': '🪝 Włosowy', 'b': 'Przynęta na włosie obok haka. Karp zasysa przynętę, hak wbija się w dolną wargę. Podstawa niemal każdego zestawu.'},
      {'t': '🪝 Blowback rig', 'b': 'Koralik pozwala hakowi swobodnie się poruszać — szybciej wbija przy krótkich braniach. Mocny na twardym, czystym dnie.'},
      {'t': '🪝 Chod rig', 'b': 'Krótki, sztywny zestaw prezentujący przynętę nad śmieciami czy mułem. Idealny na nierównym dnie.'},
      {'t': '🪝 Ronnie / spinner rig', 'b': 'Hak obraca się 360° na krętliku — bardzo ostre zacięcie. Popularny z pop-upem tuż nad dnem.'},
      {'t': '🎣 Węzeł bezwęzłowy', 'b': 'Węzeł tworzący włos i ustalający długość oraz „kick”. Włos krótki: przynęta tuż za łukiem haka.'},
      {'t': '🌽 Nęcenie wg aktywności', 'b': 'Zimna woda (<10°): mniej i drobniej; ciepła: rób dywan. Dopasuj przynętę do zanęty.'},
    ],
    'coarse': [
      {'t': '🎣 Tyczka vs feeder', 'b': 'Tyczka = precyzja z bliska dla ostrożnych ryb. Feeder = dalszy rzut i celowe nęcenie. Wybierz wg dystansu i wiatru.'},
      {'t': '🍚 Rytm nęcenia', 'b': 'Mało i często utrzymuje ławicę aktywną. Brania ustają: zmniejsz przynętę lub nęć mniej.'},
      {'t': '⚖️ Przypon i hak', 'b': 'Delikatniejszy zestaw = więcej brań w czystej, zimnej lub łowionej wodzie.'},
    ],
    'feeder': [
      {'t': '🧺 Typy koszyków', 'b': 'Open-end = rzeka/prąd, method = blisko i szybko przy przynęcie, cage = drobna zanęta, window = dozowany. Wg prądu i dystansu.'},
      {'t': '📏 Długość przyponu', 'b': 'Krótszy (20–40 cm) dla aktywnych ryb, dłuższy (60–100 cm) w ostrożnych/czystych warunkach.'},
      {'t': '🕐 Metoda klipsa', 'b': 'Zaklipsuj dystans i celuj w stały punkt na drugim brzegu — każdy rzut w to samo miejsce.'},
    ],
    'predator': [
      {'t': '🎣 Typy przynęt', 'b': 'Guma = uniwersalna, jerkbait = wolno/zimno, crankbait = szybkie przeszukiwanie, spinnerbait = mętna, topwater = ciepło i płytko.'},
      {'t': '📅 Okres ochronny (NL)', 'b': 'Szczupak: 1 mar–ostatnia sobota maja. Sandacz i okoń: 1 kwi–ostatnia sobota maja. Sprawdź swój region.'},
      {'t': '🪝 Hak stinger', 'b': 'Dodatkowy tylny hak łapie krótkie brania i chybienia — szczególnie przydatny w zimnej wodzie.'},
    ],
    'street': [
      {'t': '🎣 Zestaw ultralight', 'b': 'Główki 0,5–3 g, cienka plecionka (0,06–0,10 mm) + fluorocarbon, lekka wędka L/UL. Małe gumy.'},
      {'t': '🏙️ Miejskie miejscówki', 'b': 'Łów śluzy, mosty, dopływy, narożniki i wzdłuż nabrzeży — tam czają się drapieżniki. Bądź mobilny.'},
      {'t': '👁️ Łowienie na widoczną', 'b': 'W czystej miejskiej wodzie często widać rybę. Rzuć za nią i prowadź obok — nie na nią.'},
    ],
    'catfish': [
      {'t': '🎣 Metody', 'b': 'Spław (z prądem nad dołami), stałe/spławik (przy strukturze), klekotka (pionowo nad głębią) lub z brzegu pod nawisy.'},
      {'t': '💪 Sprzęt', 'b': 'Mocna żyłka/przypon, duże haki, solidny kołowrotek i mata XL. Sum jest silny — nie lekceważ sprzętu.'},
      {'t': '🌡️ Timing', 'b': 'Ciepłe letnie noce są najlepsze. Aromatyczne przynęty (kalmar, węgorz, pęczki robaków) w ciemnej/mętnej wodzie.'},
    ],
    'fly': [
      {'t': '🎣 Klasa linki', 'b': '#3–5 na potok/pstrąga, #6–7 uniwersalnie, #8+ na drapieżniki i morze. Cięższa = większe muchy i więcej wiatru.'},
      {'t': '🪰 Typy much', 'b': 'Sucha (powierzchnia), nimfa (pod wodą), streamer (imitacja ryby, drapieżniki), mokra (tuż pod błonką).'},
      {'t': '🌊 Dryf', 'b': 'W prądzie pozwól musze dryfować naturalnie bez „drag”. Mennduj linkę dla martwego dryfu.'},
    ],
    'trout': [
      {'t': '🎣 Łowisko vs potok', 'b': 'Łowisko = zarybione, aktywne ryby — powerbait, ciasto lub obrotówka. Potok = dzikie, płochliwe pstrągi — łów delikatnie.'},
      {'t': '🥄 Przynęta i obrotówka', 'b': 'Mała obrotówka wolno w zimnej wodzie; szybciej, gdy się ociepli. Zmieniaj kolor wg przejrzystości.'},
      {'t': '🌡️ Temperatura', 'b': 'Pstrąg lubi chłodniejszą, natlenioną wodę. Rano, wieczorem i po deszczu to najlepsze momenty.'},
    ],
    'sea': [
      {'t': '🌙 Pływy', 'b': 'Przy zmianie (ostatnia godzina przypływu / pierwsza odpływu) ryby są najaktywniejsze. Planuj wg pływów.'},
      {'t': '🧰 Zestawy', 'b': 'Paternoster = ryby denne (płastuga/dorsz), zestaw łyżkowy = płastuga, pływający/pióra = makrela i labraks w górnej warstwie.'},
      {'t': '📏 Wymiary minimalne', 'b': 'Przestrzegaj wymiarów i okresów ochronnych wg gatunku i regionu — różne w krajach. Delikatnie wypuszczaj małe ryby.'},
    ],
  },
};

// ── Helpers ──────────────────────────────────────────────────────────────────
String _vloc(BuildContext c) => Provider.of<I18n>(c, listen: false).locale;

/// Vistijl-tools UI-string in de huidige taal (val terug op EN, dan key).
String vtt(BuildContext c, String key) {
  final m = kVttStrings[key];
  return m?[_vloc(c)] ?? m?['en'] ?? key;
}

/// Checklist voor een vistijl (carp/catfish) in de huidige taal.
List<String> vttChecklist(BuildContext c, String disc) {
  final m = kVttChecklist[disc];
  if (m == null) return const [];
  return m[_vloc(c)] ?? m['en'] ?? const [];
}

/// Kennis-items voor een vistijl in de huidige taal (val terug op EN).
List<Map<String, String>> vttKnow(BuildContext c, String disc) {
  final byLoc = kVttKnow[_vloc(c)] ?? kVttKnow['en']!;
  return byLoc[disc] ?? (kVttKnow['en']![disc] ?? const []);
}

/// Media (yt/q) per kennis-item van een vistijl (taal-onafhankelijk).
List<Map<String, String>> vttKnowMedia(String disc) => kVttKnowMedia[disc] ?? const [];
