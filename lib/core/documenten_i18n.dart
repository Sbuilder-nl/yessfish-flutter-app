import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'i18n.dart';

/// Visdocumenten — landen met hun officiële instantie, en alle teksten in zes talen.
///
/// Letterlijk overgenomen uit de website (`lib/license-data.ts` en de `lic.*`-teksten), zodat de
/// app en de site hetzelfde zeggen. Bewust GEEN verzonnen regels of tarieven per land: alleen de
/// juiste officiële bron, want voorwaarden verschillen per land, regio en jaar.

class DocLand {
  const DocLand(this.code, this.vlag, this.naam, this.instantie, this.url);
  final String code, vlag, naam, instantie, url;
}

const List<DocLand> kDocLanden = [
  DocLand("NL", "🇳🇱", "Nederland", "Sportvisunie — VISpas", "https://www.vispas.nl"),
  DocLand("BE", "🇧🇪", "België", "Vlaanderen: Natuur en Bos (visverlof) · Wallonië: permis de pêche", "https://www.natuurenbos.be/visverlof"),
  DocLand("DE", "🇩🇪", "Duitsland", "Fischereischein + Angelschein (per Bundesland)", "https://www.angeln.de/angelschein/"),
  DocLand("FR", "🇫🇷", "Frankrijk", "Carte de pêche (fédérations officielles)", "https://www.cartedepeche.fr"),
  DocLand("GB", "🇬🇧", "Verenigd Koninkrijk", "Rod fishing licence (Environment Agency) + toestemming van de visrechthebbende", "https://www.gov.uk/fishing-licences"),
  DocLand("IE", "🇮🇪", "Ierland", "Inland Fisheries Ireland (zalm/zeeforel: staatsvergunning; overig per water)", "https://www.fishinginireland.info"),
  DocLand("DK", "🇩🇰", "Denemarken", "Fisketegn (staatsvergunning) + toestemming per water", "https://www.fisketegn.dk"),
  DocLand("PL", "🇵🇱", "Polen", "Karta wędkarska + zezwolenie van de beheerder (o.a. PZW)", "https://pzw.org.pl"),
  DocLand("ES", "🇪🇸", "Spanje", "Licencia de pesca per autonome regio; soms een aparte watervergunning", ""),
  DocLand("IT", "🇮🇹", "Italië", "Licenza di pesca per regio", ""),
  DocLand("AT", "🇦🇹", "Oostenrijk", "Fischerkarte per deelstaat + Lizenz per water", ""),
  DocLand("CH", "🇨🇭", "Zwitserland", "Kantonale Fischereipatent", ""),
  DocLand("CZ", "🇨🇿", "Tsjechië", "Rybářský lístek + povolenka (ČRS/MRS)", ""),
  DocLand("SE", "🇸🇪", "Zweden", "Fiskekort per water (vaak via iFiske)", ""),
  DocLand("NO", "🇳🇴", "Noorwegen", "Fiskeravgift bij zalm/zeeforel + fiskekort per water", ""),
  DocLand("FI", "🇫🇮", "Finland", "Kalastonhoitomaksu (visbeheerbijdrage) + toestemming per water", ""),
  DocLand("LU", "🇱🇺", "Luxemburg", "Permis de pêche (Administration de la gestion de l’eau)", ""),
  DocLand("HR", "🇭🇷", "Kroatië", "Dozvola za ribolov per beheerder", ""),
  DocLand("HU", "🇭🇺", "Hongarije", "Állami horgászjegy + területi jegy", ""),
  DocLand("PT", "🇵🇹", "Portugal", "Licença de pesca (ICNF)", ""),
  DocLand("XX", "🇪🇺", "Overig / EU", "Raadpleeg de nationale visserij-instantie van het betreffende land", ""),
];

DocLand docLand(String code) => kDocLanden.firstWhere((l) => l.code == code,
    orElse: () => kDocLanden.last);

/// Soorten documenten die leden echt hebben (zelfde volgorde als op het web).
const List<String> kDocTypes = [
  'vispas', 'fiskfergunning', 'viskaart', 'nacht', 'derde_hengel',
  'clubvergunning', 'dagvergunning', 'permit', 'overig',
];

const Map<String, Map<String, String>> _doc = {
  "lic.foto_achter": {"nl": "Achterkant", "en": "Back", "de": "Rückseite", "fr": "Verso", "es": "Reverso", "pl": "Tył"},
  "lic.foto_camera": {"nl": "Camera", "en": "Camera", "de": "Kamera", "fr": "Appareil photo", "es": "Cámara", "pl": "Aparat"},
  "lic.foto_fout": {"nl": "Uploaden lukte niet. Probeer een kleinere foto.", "en": "Upload failed. Try a smaller photo.", "de": "Upload fehlgeschlagen. Versuch ein kleineres Foto.", "fr": "Envoi impossible. Essaie une photo plus petite.", "es": "No se pudo subir. Prueba con una foto más pequeña.", "pl": "Nie udało się wysłać. Spróbuj mniejsze zdjęcie."},
  "lic.foto_galerij": {"nl": "Uit je galerij", "en": "From your gallery", "de": "Aus der Galerie", "fr": "Depuis la galerie", "es": "Desde la galería", "pl": "Z galerii"},
  "lic.foto_let_op": {"nl": "Alleen jij ziet deze foto. Let op: een foto vervangt je pas niet — bij een controle moet je de échte VISpas of vergunning kunnen laten zien.", "en": "Only you can see this photo. Note: a photo does not replace your permit — during a check you must be able to show the real one.", "de": "Nur du siehst dieses Foto. Achtung: ein Foto ersetzt die Erlaubnis nicht — bei einer Kontrolle musst du das Original zeigen können.", "fr": "Toi seul vois cette photo. Attention : une photo ne remplace pas le permis — lors d’un contrôle, tu dois pouvoir montrer l’original.", "es": "Solo tú ves esta foto. Atención: una foto no sustituye la licencia — en un control debes poder mostrar la original.", "pl": "Tylko ty widzisz to zdjęcie. Uwaga: zdjęcie nie zastępuje zezwolenia — podczas kontroli musisz pokazać oryginał."},
  "lic.foto_toevoegen": {"nl": "Foto toevoegen", "en": "Add photo", "de": "Foto hinzufügen", "fr": "Ajouter une photo", "es": "Añadir foto", "pl": "Dodaj zdjęcie"},
  "lic.foto_vervangen": {"nl": "Vervangen", "en": "Replace", "de": "Ersetzen", "fr": "Remplacer", "es": "Sustituir", "pl": "Zamień"},
  "lic.foto_voor": {"nl": "Voorkant", "en": "Front", "de": "Vorderseite", "fr": "Recto", "es": "Anverso", "pl": "Przód"},
  "lic.foto_weg": {"nl": "Verwijderen", "en": "Remove", "de": "Entfernen", "fr": "Supprimer", "es": "Eliminar", "pl": "Usuń"},

  "lic.add": {"nl": "Document toevoegen", "en": "Add document", "de": "Dokument hinzufügen", "fr": "Ajouter un document", "es": "Añadir documento", "pl": "Dodaj dokument"},
  "lic.cancel": {"nl": "Annuleren", "en": "Cancel", "de": "Abbrechen", "fr": "Annuler", "es": "Cancelar", "pl": "Anuluj"},
  "lic.confirm_delete": {"nl": "Dit visdocument verwijderen?", "en": "Delete this permit?", "de": "Dieses Dokument löschen?", "fr": "Supprimer ce document ?", "es": "¿Eliminar esta licencia?", "pl": "Usunąć to zezwolenie?"},
  "lic.country": {"nl": "Land", "en": "Country", "de": "Land", "fr": "Pays", "es": "País", "pl": "Kraj"},
  "lic.disclaimer": {"nl": "Indicatief overzicht voor jezelf. Voorwaarden, maten en geldigheid verschillen per land, regio en jaar — controleer altijd de officiële instantie.", "en": "Indicative overview for yourself. Conditions, sizes and validity differ per country, region and year — always check the official authority.", "de": "Indikative Übersicht für dich selbst. Bedingungen, Maße und Gültigkeit unterscheiden sich je Land, Region und Jahr — prüfe immer die offizielle Behörde.", "fr": "Aperçu indicatif pour vous-même. Les conditions, tailles et validités varient selon le pays, la région et l’année — vérifiez toujours l’autorité officielle.", "es": "Resumen orientativo para ti mismo. Las condiciones, tallas y validez difieren según el país, la región y el año — consulta siempre la autoridad oficial.", "pl": "Orientacyjny przegląd dla Ciebie. Warunki, wymiary i ważność różnią się w zależności od kraju, regionu i roku — zawsze sprawdzaj oficjalny urząd."},
  "lic.edit": {"nl": "Document bewerken", "en": "Edit document", "de": "Dokument bearbeiten", "fr": "Modifier le document", "es": "Editar documento", "pl": "Edytuj dokument"},
  "lic.holder": {"nl": "Op naam van", "en": "Held by", "de": "Inhaber", "fr": "Au nom de", "es": "Titular", "pl": "Posiadacz"},
  "lic.issuer": {"nl": "Uitgevende instantie", "en": "Issuing authority", "de": "Ausstellende Behörde", "fr": "Autorité émettrice", "es": "Autoridad emisora", "pl": "Organ wydający"},
  "lic.name": {"nl": "Naam / omschrijving", "en": "Name / description", "de": "Name / Beschreibung", "fr": "Nom / description", "es": "Nombre / descripción", "pl": "Nazwa / opis"},
  "lic.name_ph": {"nl": "bv. VISpas HSV Steenwijk", "en": "e.g. VISpas angling club", "de": "z. B. Angelschein Verein", "fr": "p. ex. carte de pêche club", "es": "p. ej. VISpas club de pesca", "pl": "np. VISpas klub wędkarski"},
  "lic.none": {"nl": "Nog geen visdocumenten toegevoegd.", "en": "No fishing permits added yet.", "de": "Noch keine Angeldokumente hinzugefügt.", "fr": "Aucun document de pêche ajouté.", "es": "Aún no has añadido ninguna licencia de pesca.", "pl": "Jeszcze nie dodano zezwoleń wędkarskich."},
  "lic.notes": {"nl": "Notities", "en": "Notes", "de": "Notizen", "fr": "Notes", "es": "Notas", "pl": "Notatki"},
  "lic.number": {"nl": "Nummer", "en": "Number", "de": "Nummer", "fr": "Numéro", "es": "Número", "pl": "Numer"},
  "lic.official_source": {"nl": "Officiële bron", "en": "Official source", "de": "Offizielle Quelle", "fr": "Source officielle", "es": "Fuente oficial", "pl": "Oficjalne źródło"},
  "lic.overzicht": {"nl": "Jouw documenten", "en": "Your documents", "de": "Deine Dokumente", "fr": "Tes documents", "es": "Tus documentos", "pl": "Twoje dokumenty"},
  "lic.overzicht_sub": {"nl": "%d documenten in %d landen", "en": "%d documents in %d countries", "de": "%d Dokumente in %d Ländern", "fr": "%d documents dans %d pays", "es": "%d documentos en %d países", "pl": "%d dokumentów w %d krajach"},
  "lic.save": {"nl": "Opslaan", "en": "Save", "de": "Speichern", "fr": "Enregistrer", "es": "Guardar", "pl": "Zapisz"},
  "lic.status_expired": {"nl": "Verlopen", "en": "Expired", "de": "Abgelaufen", "fr": "Expiré", "es": "Caducada", "pl": "Wygasłe"},
  "lic.status_soon": {"nl": "Verloopt binnenkort", "en": "Expiring soon", "de": "Läuft bald ab", "fr": "Expire bientôt", "es": "Caduca pronto", "pl": "Wkrótce wygasa"},
  "lic.status_valid": {"nl": "Geldig", "en": "Valid", "de": "Gültig", "fr": "Valable", "es": "Válida", "pl": "Ważne"},
  "lic.subtitle": {"nl": "Bewaar je VISpas, vergunning of permit op één plek — met de juiste officiële bron per land.", "en": "Keep your fishing license or permit in one place — with the correct official source per country.", "de": "Bewahre deinen Angelschein oder deine Erlaubnis an einem Ort auf — mit der richtigen offiziellen Quelle pro Land.", "fr": "Gardez votre carte ou permis de pêche au même endroit — avec la bonne source officielle par pays.", "es": "Guarda tu licencia o permiso de pesca en un solo lugar — con la fuente oficial correcta por país.", "pl": "Trzymaj swoją kartę lub zezwolenie wędkarskie w jednym miejscu — z właściwym oficjalnym źródłem dla każdego kraju."},
  "lic.title": {"nl": "Mijn visdocumenten", "en": "My fishing permits", "de": "Meine Angeldokumente", "fr": "Mes documents de pêche", "es": "Mis licencias de pesca", "pl": "Moje zezwolenia wędkarskie"},
  "lic.type": {"nl": "Type", "en": "Type", "de": "Typ", "fr": "Type", "es": "Tipo", "pl": "Typ"},
  "lic.type_clubvergunning": {"nl": "Verenigingsvergunning", "en": "Club permit", "de": "Vereinserlaubnis", "fr": "Permis d’association", "es": "Permiso del club", "pl": "Zezwolenie koła"},
  "lic.type_dagvergunning": {"nl": "Dag- of weekvergunning", "en": "Day or week permit", "de": "Tages- oder Wochenkarte", "fr": "Carte à la journée ou semaine", "es": "Permiso de día o semana", "pl": "Zezwolenie dzienne lub tygodniowe"},
  "lic.type_derde_hengel": {"nl": "Derde hengel", "en": "Third rod", "de": "Dritte Rute", "fr": "Troisième canne", "es": "Tercera caña", "pl": "Trzecia wędka"},
  "lic.type_fiskfergunning": {"nl": "Fiskfergunning (Fryslân)", "en": "Fiskfergunning (Fryslân)", "de": "Fiskfergunning (Fryslân)", "fr": "Fiskfergunning (Fryslân)", "es": "Fiskfergunning (Fryslân)", "pl": "Fiskfergunning (Fryslân)"},
  "lic.type_nacht": {"nl": "Nachtvistoestemming", "en": "Night fishing permit", "de": "Nachtangel-Erlaubnis", "fr": "Autorisation de pêche de nuit", "es": "Permiso de pesca nocturna", "pl": "Zezwolenie na połów nocny"},
  "lic.type_overig": {"nl": "Overig", "en": "Other", "de": "Sonstige", "fr": "Autre", "es": "Otro", "pl": "Inne"},
  "lic.type_permit": {"nl": "Permit", "en": "Permit", "de": "Permit", "fr": "Permis", "es": "Permiso", "pl": "Zezwolenie"},
  "lic.type_vergunning": {"nl": "Vergunning", "en": "Permit", "de": "Erlaubnis", "fr": "Permis", "es": "Permiso", "pl": "Zezwolenie"},
  "lic.type_viskaart": {"nl": "Viskaart (NHO)", "en": "Viskaart (NHO)", "de": "Viskaart (NHO)", "fr": "Viskaart (NHO)", "es": "Viskaart (NHO)", "pl": "Viskaart (NHO)"},
  "lic.type_vispas": {"nl": "VISpas", "en": "VISpas", "de": "VISpas", "fr": "VISpas", "es": "VISpas", "pl": "VISpas"},
  "lic.valid_from": {"nl": "Geldig vanaf", "en": "Valid from", "de": "Gültig ab", "fr": "Valable à partir du", "es": "Válida desde", "pl": "Ważne od"},
  "lic.valid_until": {"nl": "Geldig tot", "en": "Valid until", "de": "Gültig bis", "fr": "Valable jusqu’au", "es": "Válida hasta", "pl": "Ważne do"},
  "lic.verloopt": {"nl": "%d verloopt binnenkort", "en": "%d expiring soon", "de": "%d läuft bald ab", "fr": "%d expire bientôt", "es": "%d caduca pronto", "pl": "%d wkrótce wygasa"},
  "lic.verlopen": {"nl": "%d verlopen", "en": "%d expired", "de": "%d abgelaufen", "fr": "%d expirés", "es": "%d caducados", "pl": "%d wygasłych"},
};

String dt(BuildContext c, String k, [Map<String, String>? v]) {
  final l = Provider.of<I18n>(c, listen: false).locale;
  var s = _doc[k]?[l] ?? _doc[k]?['en'] ?? k;
  v?.forEach((a, b) => s = s.replaceAll(a, b));
  return s;
}
