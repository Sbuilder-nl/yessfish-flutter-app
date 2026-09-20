import 'rondleiding.dart';

/// De rondleiding door de app, hoofdstuk voor hoofdstuk.
///
/// Zelfde opzet als op het web: elk hoofdstuk hoort bij één plek in de app en legt van A tot Z
/// uit wat je daar kunt, door de échte knop aan te wijzen. De `zoek`-waarde is de anker-id die
/// met `TourAnker(id: ...)` om die knop staat — het app-equivalent van `data-tour` op het web.
///
/// Teksten zijn met opzet gelijk aan het web waar de functie gelijk is. Namen die een lid kent
/// uit de app winnen het van de webnaam (Richard 17-09-2026: "bij twijfel wint de app").

const int _tabFeed = 0;
const int _tabVangsten = 1;
const int _tabBijtkans = 2;
const int _tabKaart = 3;
const int _tabMenu = 4;

final List<Hoofdstuk> hoofdstukken = [
  // ── 1. Eerste stappen ───────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'start', icoon: '👋',
    naam: tx('Eerste stappen', 'First steps', 'Erste Schritte', 'Premiers pas', 'Primeros pasos', 'Pierwsze kroki'),
    samenvatting: tx('Wat is YessFish en waar vind je alles?', 'What is YessFish and where is everything?',
        'Was ist YessFish und wo findest du alles?', 'Qu’est-ce que YessFish et où trouver quoi ?',
        '¿Qué es YessFish y dónde está todo?', 'Czym jest YessFish i gdzie co znajdziesz?'),
    stappen: [
      Stap(id: 'start-welkom', tab: _tabFeed,
        titel: tx('Welkom', 'Welcome', 'Willkommen', 'Bienvenue', 'Bienvenido', 'Witaj'),
        tekst: tx(
          'YessFish is je visboek, je viskaart en je vismaten in één. We lopen samen door de app zodat je weet waar alles staat. Je kunt altijd stoppen en later verdergaan — je komt terug waar je gebleven was.',
          'YessFish is your logbook, your map and your fishing buddies in one. We will walk through the app together so you know where everything is. You can stop any time and pick up where you left off.',
          'YessFish ist Fangbuch, Karte und Angelkumpels in einem. Wir gehen zusammen durch die App, damit du weißt, wo alles ist. Du kannst jederzeit aufhören und später weitermachen.',
          'YessFish, c’est ton carnet, ta carte et tes copains de pêche en un. On parcourt l’app ensemble pour que tu saches où tout se trouve. Tu peux arrêter et reprendre plus tard.',
          'YessFish es tu diario, tu mapa y tus compañeros de pesca en uno. Recorremos la app juntos para que sepas dónde está todo. Puedes parar y continuar más tarde.',
          'YessFish to dziennik, mapa i koledzy wędkarze w jednym. Przejdziemy przez aplikację razem, żebyś wiedział, gdzie co jest. Możesz przerwać i wrócić później.')),
      Stap(id: 'start-tabs', tab: _tabFeed, zoek: 'nav-balk',
        titel: tx('De vijf tabbladen', 'The five tabs', 'Die fünf Tabs', 'Les cinq onglets', 'Las cinco pestañas', 'Pięć zakładek'),
        tekst: tx(
          'Onderaan staan vijf tabbladen: Feed, Vangsten, Bijtkans, Kaart en Menu. Hier kom je overal vandaan weer terug. We lopen ze allemaal langs.',
          'At the bottom are five tabs: Feed, Catches, Bite, Map and Menu. From here you can always get back. We will visit them all.',
          'Unten sind fünf Tabs: Feed, Fänge, Beißzeit, Karte und Menü. Von hier kommst du überall wieder zurück. Wir schauen sie uns alle an.',
          'En bas, cinq onglets : Fil, Prises, Mordant, Carte et Menu. D’ici tu reviens toujours. On va tous les voir.',
          'Abajo hay cinco pestañas: Feed, Capturas, Picada, Mapa y Menú. Desde aquí siempre vuelves. Las veremos todas.',
          'Na dole jest pięć zakładek: Feed, Połowy, Branie, Mapa i Menu. Stąd zawsze wrócisz. Obejrzymy wszystkie.')),
      Stap(id: 'start-reeks', tab: _tabFeed, zoek: 'reeks-balk', optioneel: true,
        titel: tx('Je dobber-reeks', 'Your float streak', 'Deine Posen-Serie', 'Ta série de bouchons', 'Tu racha de flotadores', 'Twoja seria spławików'),
        tekst: tx(
          'Elke dag dat je iets doet in de app verdien je een dobber. Zeven dagen op rij maakt de ronde vol. Dobbers gebruik je voor extra functies zoals de wateranalyse.',
          'Every day you do something in the app you earn a float. Seven days in a row completes the round. Use floats for extras such as the water analysis.',
          'Für jeden Tag, an dem du etwas in der App machst, bekommst du eine Pose. Sieben Tage am Stück füllen die Runde. Posen nutzt du für Extras wie die Gewässeranalyse.',
          'Chaque jour où tu fais quelque chose dans l’app, tu gagnes un bouchon. Sept jours d’affilée complètent le tour. Les bouchons servent aux extras comme l’analyse de l’eau.',
          'Cada día que haces algo en la app ganas un flotador. Siete días seguidos completan la ronda. Los flotadores sirven para extras como el análisis del agua.',
          'Za każdy dzień aktywności dostajesz spławik. Siedem dni z rzędu zamyka rundę. Spławiki wykorzystasz na dodatki, np. analizę wody.')),
    ],
  ),

  // ── 2. De feed ──────────────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'feed', icoon: '📣',
    naam: tx('De feed', 'The feed', 'Der Feed', 'Le fil', 'El feed', 'Feed'),
    samenvatting: tx('Wat je vismaten vangen, en zelf iets plaatsen.', 'What your buddies catch, and posting yourself.',
        'Was deine Kumpels fangen, und selbst posten.', 'Ce que pêchent tes copains, et publier toi-même.',
        'Lo que pescan tus amigos, y publicar tú mismo.', 'Co łowią koledzy i jak sam opublikujesz.'),
    stappen: [
      Stap(id: 'feed-lijst', tab: _tabFeed,
        titel: tx('Wat er gebeurt', 'What is happening', 'Was passiert', 'Ce qui se passe', 'Lo que pasa', 'Co się dzieje'),
        tekst: tx(
          'Hier zie je vangsten en berichten van je vismaten en van YessFish. Trek het scherm naar beneden om te verversen.',
          'Here you see catches and posts from your buddies and from YessFish. Pull down to refresh.',
          'Hier siehst du Fänge und Beiträge deiner Kumpels und von YessFish. Zum Aktualisieren nach unten ziehen.',
          'Ici tu vois les prises et messages de tes copains et de YessFish. Tire vers le bas pour actualiser.',
          'Aquí ves capturas y mensajes de tus amigos y de YessFish. Tira hacia abajo para actualizar.',
          'Tu widzisz połowy i wpisy kolegów oraz YessFish. Pociągnij w dół, aby odświeżyć.')),
      Stap(id: 'feed-plaatsen', tab: _tabFeed, zoek: 'feed-plaatsen', optioneel: true,
        titel: tx('Zelf iets plaatsen', 'Post something yourself', 'Selbst etwas posten', 'Publier toi-même', 'Publicar tú mismo', 'Opublikuj coś'),
        tekst: tx(
          'Met deze knop plaats je een bericht met foto of video. Handig om een mooie dag te delen zonder dat het een vangst is.',
          'This button posts a message with a photo or video. Handy to share a good day that is not a catch.',
          'Mit dieser Taste postest du einen Beitrag mit Foto oder Video. Praktisch für einen schönen Tag ohne Fang.',
          'Ce bouton publie un message avec photo ou vidéo. Pratique pour partager une belle journée sans prise.',
          'Con este botón publicas un mensaje con foto o vídeo. Útil para compartir un buen día sin captura.',
          'Tym przyciskiem opublikujesz wpis ze zdjęciem lub filmem. Przydatne, gdy nie masz połowu.')),
    ],
  ),

  // ── 3. Vangsten ─────────────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'vangsten', icoon: '🎣',
    naam: tx('Je vangsten', 'Your catches', 'Deine Fänge', 'Tes prises', 'Tus capturas', 'Twoje połowy'),
    samenvatting: tx('Vangst melden, meerdere vissen tegelijk, en concepten.',
        'Log a catch, several fish at once, and drafts.', 'Fang melden, mehrere Fische auf einmal, und Entwürfe.',
        'Déclarer une prise, plusieurs poissons, et brouillons.', 'Registrar captura, varios peces, y borradores.',
        'Zgłoś połów, kilka ryb naraz i szkice.'),
    stappen: [
      Stap(id: 'vangst-lijst', tab: _tabVangsten,
        titel: tx('Je visboek', 'Your logbook', 'Dein Fangbuch', 'Ton carnet', 'Tu diario', 'Twój dziennik'),
        tekst: tx(
          'Al je vangsten staan hier bij elkaar, met foto, gewicht en water. Dit is je eigen visboek — alleen jij bepaalt wat je deelt.',
          'All your catches are here, with photo, weight and water. This is your own logbook — you decide what you share.',
          'Alle deine Fänge an einem Ort, mit Foto, Gewicht und Gewässer. Dein eigenes Fangbuch — du entscheidest, was du teilst.',
          'Toutes tes prises ici, avec photo, poids et eau. Ton carnet à toi — tu décides ce que tu partages.',
          'Todas tus capturas aquí, con foto, peso y agua. Tu propio diario — tú decides qué compartes.',
          'Wszystkie połowy w jednym miejscu, ze zdjęciem, wagą i wodą. Twój dziennik — sam decydujesz, co udostępnisz.')),
      // Bewust géén `klik: true`: deze knop opent een nieuw scherm, en dan zou de rondleiding als
      // donkere laag over dat formulier blijven liggen en gewoon doorlopen. Op de emulator gezien
      // — stap 10 stond ineens over "Nieuwe vangst" heen. Meelopen door een geopend scherm vraagt
      // een eigen ontwerp; dat komt in de volgende ronde (Richard 19-09-2026).
      Stap(id: 'vangst-nieuw', tab: _tabVangsten, zoek: 'vangst-nieuw',
        titel: tx('Vangst melden', 'Log a catch', 'Fang melden', 'Déclarer une prise', 'Registrar captura', 'Zgłoś połów'),
        tekst: tx(
          'Met deze knop meld je een vangst: soort, gewicht, foto en het water. Ving je meerdere soorten, dan voeg je die in één melding toe met een aantal erbij — vul bij het gewicht dat van de zwaarste vis in.',
          'This button logs a catch: species, weight, photo and the water. Caught several species? Add them in one report with a number each — for weight, enter the heaviest fish.',
          'Mit dieser Taste meldest du einen Fang: Art, Gewicht, Foto und Gewässer. Mehrere Arten? Trag sie in einer Meldung mit Anzahl ein — beim Gewicht den schwersten Fisch.',
          'Ce bouton déclare une prise : espèce, poids, photo et l’eau. Plusieurs espèces ? Ajoute-les en une déclaration avec un nombre — pour le poids, le plus lourd.',
          'Con este botón registras una captura: especie, peso, foto y el agua. ¿Varias especies? Añádelas en un registro con cantidad — en peso, el más pesado.',
          'Tym przyciskiem zgłaszasz połów: gatunek, waga, zdjęcie i woda. Spróbuj zaraz po przewodniku.')),
      Stap(id: 'vangst-concepten', tab: _tabVangsten, zoek: 'vangst-concepten', optioneel: true,
        titel: tx('Conceptvangsten', 'Draft catches', 'Fang-Entwürfe', 'Prises en brouillon', 'Capturas en borrador', 'Szkice połowów'),
        tekst: tx(
          'Snel aan de waterkant gemeld met de snelvangst? Dan staat hij hier als concept. Thuis maak je hem af — ook op de site. Punten tellen pas als de vangst af is.',
          'Logged quickly at the water with quick catch? It sits here as a draft. Finish it at home — on the website too. Points only count once it is finished.',
          'Schnell am Wasser per Schnellfang gemeldet? Dann liegt er hier als Entwurf. Zu Hause machst du ihn fertig — auch auf der Website. Punkte zählen erst, wenn er fertig ist.',
          'Déclaré vite au bord de l’eau avec la prise rapide ? Elle est ici en brouillon. Tu la termines chez toi — aussi sur le site. Les points comptent une fois terminée.',
          '¿Registrada rápido en la orilla con captura rápida? Queda aquí como borrador. La terminas en casa — también en la web. Los puntos cuentan al terminarla.',
          'Zgłoszone szybko nad wodą? Czeka tu jako szkic. Dokończysz w domu — także na stronie. Punkty liczą się dopiero po ukończeniu.')),
    ],
  ),

  // ── 4. Bijtkans ─────────────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'bijtkans', icoon: '🌤️',
    naam: tx('Bijtkans', 'Bite forecast', 'Beißzeit', 'Mordant', 'Picada', 'Branie'),
    samenvatting: tx('Wanneer is het kansrijk om te gaan?', 'When is it worth going?',
        'Wann lohnt sich das Angeln?', 'Quand ça vaut le coup d’y aller ?', '¿Cuándo vale la pena ir?', 'Kiedy warto iść?'),
    stappen: [
      Stap(id: 'bijt-score', tab: _tabBijtkans,
        titel: tx('De bijtkans', 'The bite score', 'Die Beißchance', 'La chance de touche', 'La probabilidad de picada', 'Szansa na branie'),
        tekst: tx(
          'Dit cijfer schat hoe kansrijk het nu is op jouw plek. Het kijkt naar weer, luchtdruk, maanstand, seizoen en wat er in de buurt gevangen wordt.',
          'This number estimates how promising it is right now at your spot. It looks at weather, pressure, moon, season and nearby catches.',
          'Diese Zahl schätzt, wie aussichtsreich es gerade an deiner Stelle ist: Wetter, Luftdruck, Mond, Jahreszeit und Fänge in der Nähe.',
          'Ce chiffre estime les chances à ton endroit : météo, pression, lune, saison et prises à proximité.',
          'Este número estima las opciones en tu sitio: tiempo, presión, luna, temporada y capturas cercanas.',
          'Ta liczba szacuje szanse w twoim miejscu: pogoda, ciśnienie, księżyc, pora roku i pobliskie połowy.')),
      Stap(id: 'bijt-factoren', tab: _tabBijtkans, zoek: 'bijt-factoren', optioneel: true,
        titel: tx('Waarom dat cijfer?', 'Why that number?', 'Warum diese Zahl?', 'Pourquoi ce chiffre ?', '¿Por qué ese número?', 'Dlaczego ta liczba?'),
        tekst: tx(
          'Elke factor staat er los bij, met uitleg. Zo zie je of het aan de druk ligt, aan het seizoen, of aan wat er in de buurt gevangen wordt.',
          'Every factor is listed separately, with an explanation. So you see whether it is the pressure, the season, or nearby catches.',
          'Jeder Faktor steht einzeln da, mit Erklärung. So siehst du, ob es am Druck, an der Jahreszeit oder an Fängen in der Nähe liegt.',
          'Chaque facteur est détaillé, avec explication. Tu vois si c’est la pression, la saison ou les prises proches.',
          'Cada factor aparece por separado, con explicación. Así ves si es la presión, la temporada o las capturas cercanas.',
          'Każdy czynnik osobno, z wyjaśnieniem. Widzisz, czy chodzi o ciśnienie, porę roku czy pobliskie połowy.')),
    ],
  ),

  // ── 5. De viskaart ──────────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'kaart', icoon: '🗺️',
    naam: tx('De viskaart', 'The map', 'Die Karte', 'La carte', 'El mapa', 'Mapa'),
    samenvatting: tx('Wateren vinden, stekken plaatsen, zien wat er mag.',
        'Find waters, place spots, see what is allowed.', 'Gewässer finden, Stellen setzen, sehen was erlaubt ist.',
        'Trouver des eaux, poser des spots, voir ce qui est permis.', 'Encontrar aguas, poner puntos, ver qué se permite.',
        'Znajdź wody, dodaj stanowiska, sprawdź zasady.'),
    stappen: [
      Stap(id: 'kaart-overzicht', tab: _tabKaart,
        titel: tx('Alles op de kaart', 'Everything on the map', 'Alles auf der Karte', 'Tout sur la carte', 'Todo en el mapa', 'Wszystko na mapie'),
        tekst: tx(
          'Elke groene dobber is een viswater. De kleur zegt hoe druk het er is: groen rustig, oranje gemiddeld, rood druk, grijs onbekend.',
          'Every green float is a fishing water. The colour shows how busy it is: green quiet, orange average, red busy, grey unknown.',
          'Jede grüne Pose ist ein Angelgewässer. Die Farbe zeigt, wie voll es ist: grün ruhig, orange mittel, rot voll, grau unbekannt.',
          'Chaque bouchon vert est une eau de pêche. La couleur indique l’affluence : vert calme, orange moyen, rouge chargé, gris inconnu.',
          'Cada flotador verde es un agua de pesca. El color indica la afluencia: verde tranquilo, naranja medio, rojo concurrido, gris desconocido.',
          'Każdy zielony spławik to łowisko. Kolor pokazuje ruch: zielony spokojnie, pomarańczowy średnio, czerwony tłoczno, szary brak danych.')),
      Stap(id: 'kaart-zoeken', tab: _tabKaart, zoek: 'kaart-zoeken', optioneel: true,
        titel: tx('Zoeken op de kaart', 'Search the map', 'Auf der Karte suchen', 'Chercher sur la carte', 'Buscar en el mapa', 'Szukaj na mapie'),
        tekst: tx(
          'Met de zoekknop vind je een water of een plaats op naam. Handig als je gaat vissen waar je nog nooit geweest bent.',
          'The search button finds a water or a place by name. Handy when you are fishing somewhere you have never been.',
          'Mit der Suche findest du ein Gewässer oder einen Ort über den Namen. Praktisch, wenn du irgendwo angelst, wo du noch nie warst.',
          'Le bouton de recherche trouve une eau ou un lieu par son nom. Pratique quand tu pêches dans un endroit inconnu.',
          'Con el botón de búsqueda encuentras un agua o un lugar por su nombre. Útil cuando pescas donde nunca has estado.',
          'Przyciskiem szukania znajdziesz wodę albo miejscowość po nazwie. Przydatne, gdy jedziesz gdzieś pierwszy raz.')),
      Stap(id: 'kaart-lagen', tab: _tabKaart, zoek: 'kaart-lagen', optioneel: true,
        titel: tx('Lagen', 'Layers', 'Ebenen', 'Couches', 'Capas', 'Warstwy'),
        tekst: tx(
          'Hier zet je aan wat je wilt zien: wateren, je eigen stekken, winkels, verenigingen, jachthavens en de dieptekaart.',
          'Here you switch on what you want to see: waters, your own spots, shops, clubs, marinas and the depth map.',
          'Hier schaltest du ein, was du sehen willst: Gewässer, eigene Stellen, Läden, Vereine, Marinas und die Tiefenkarte.',
          'Ici tu actives ce que tu veux voir : eaux, tes spots, magasins, associations, ports et la carte des profondeurs.',
          'Aquí activas lo que quieres ver: aguas, tus puntos, tiendas, clubes, puertos y el mapa de profundidad.',
          'Tu włączasz, co chcesz widzieć: wody, swoje stanowiska, sklepy, kluby, mariny i mapę głębokości.')),
      Stap(id: 'kaart-dieptemenu', tab: _tabKaart, zoek: 'kaart-lagen', optioneel: true,
        titel: tx('Diepte van een water', 'Depth of a water', 'Tiefe eines Gewässers', 'Profondeur d’une eau', 'Profundidad de un agua', 'Głębokość wody'),
        tekst: tx(
          'Onder Lagen staat welke wateren dieptedata hebben: wat je al hebt en wat je kunt ontgrendelen. Deel je zelf metingen, dan kijk je daar gratis.',
          'Under Layers you see which waters have depth data: what you already have and what you can unlock. Share your own soundings and you look there for free.',
          'Unter Ebenen siehst du, welche Gewässer Tiefendaten haben: was du schon hast und was du freischalten kannst. Teilst du selbst Messungen, schaust du dort gratis.',
          'Sous Couches tu vois quelles eaux ont des données de profondeur : ce que tu as déjà et ce que tu peux débloquer. Si tu partages tes relevés, c’est gratuit.',
          'En Capas ves qué aguas tienen datos de profundidad: lo que ya tienes y lo que puedes desbloquear. Si compartes tus mediciones, allí miras gratis.',
          'W Warstwach widzisz, które wody mają dane o głębokości: co już masz i co możesz odblokować. Jeśli sam udostępniasz pomiary, patrzysz tam za darmo.')),
      Stap(id: 'kaart-plus', tab: _tabKaart, zoek: 'kaart-plus', optioneel: true,
        titel: tx('De plusknop', 'The plus button', 'Die Plus-Taste', 'Le bouton plus', 'El botón más', 'Przycisk plus'),
        tekst: tx(
          'Hiermee voeg je iets toe: een stek op een bekend water, of een water dat nog niet op de kaart staat.',
          'Use this to add something: a spot on a known water, or a water that is not on the map yet.',
          'Damit fügst du etwas hinzu: eine Stelle an einem bekannten Gewässer oder ein noch fehlendes Gewässer.',
          'Pour ajouter quelque chose : un spot sur une eau connue, ou une eau absente de la carte.',
          'Para añadir algo: un punto en un agua conocida, o un agua que falta en el mapa.',
          'Tym dodasz coś: stanowisko na znanej wodzie lub wodę, której jeszcze nie ma.')),
    ],
  ),

  // ── 6. Je gereedschap ───────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'gereedschap', icoon: '🧰',
    naam: tx('Je gereedschap', 'Your tools', 'Dein Werkzeug', 'Tes outils', 'Tus herramientas', 'Twoje narzędzia'),
    samenvatting: tx('Vis herkennen, je uitrusting en je papieren.', 'Identify fish, your tackle and your papers.',
        'Fische bestimmen, deine Ausrüstung und deine Papiere.', 'Identifier un poisson, ton matériel et tes papiers.',
        'Identificar peces, tu equipo y tus papeles.', 'Rozpoznawanie ryb, sprzęt i dokumenty.'),
    stappen: [
      Stap(id: 'menu-herkennen', tab: _tabMenu, zoek: 'menu-herkennen', optioneel: true,
        titel: tx('Vis herkennen', 'Identify a fish', 'Fisch bestimmen', 'Reconnaître un poisson', 'Identificar un pez', 'Rozpoznaj rybę'),
        tekst: tx(
          'Weet je niet wat je hebt gevangen? Maak een foto, dan zoekt de app de soort erbij. Een foto uit je galerij werkt ook.',
          'Not sure what you caught? Take a photo and the app looks up the species. A photo from your gallery works too.',
          'Du weißt nicht, was du gefangen hast? Mach ein Foto, die App sucht die Art heraus. Ein Foto aus der Galerie geht auch.',
          'Tu ne sais pas ce que tu as pris ? Prends une photo, l’app trouve l’espèce. Une photo de ta galerie marche aussi.',
          '¿No sabes qué has pescado? Haz una foto y la app busca la especie. Una foto de tu galería también vale.',
          'Nie wiesz, co złowiłeś? Zrób zdjęcie, a aplikacja podpowie gatunek. Zdjęcie z galerii też zadziała.')),
      Stap(id: 'menu-uitrusting', tab: _tabMenu, zoek: 'menu-uitrusting', optioneel: true,
        titel: tx('Je uitrusting', 'Your tackle', 'Deine Ausrüstung', 'Ton matériel', 'Tu equipo', 'Twój sprzęt'),
        tekst: tx(
          'Hier zet je je hengels, molens en aas op een rij. Bij een vangst kies je er dan uit waarmee je viste.',
          'Here you list your rods, reels and bait. When you log a catch you pick what you fished with.',
          'Hier trägst du Ruten, Rollen und Köder ein. Beim Fang wählst du dann aus, womit du geangelt hast.',
          'Ici tu listes tes cannes, moulinets et appâts. À chaque prise, tu choisis avec quoi tu pêchais.',
          'Aquí apuntas tus cañas, carretes y cebos. Al registrar una captura eliges con qué pescabas.',
          'Tu wpisujesz swoje wędki, kołowrotki i przynęty. Przy połowie wybierzesz, czym łowiłeś.')),
      Stap(id: 'menu-documenten', tab: _tabMenu, zoek: 'menu-documenten', optioneel: true,
        titel: tx('Je visdocumenten', 'Your fishing documents', 'Deine Angeldokumente', 'Tes documents de pêche', 'Tus documentos de pesca', 'Twoje dokumenty'),
        tekst: tx(
          'Bewaar hier je VISpas en andere vergunningen, met een foto erbij. Bij een controle aan de waterkant heb je ze meteen bij de hand.',
          'Keep your fishing licence and other permits here, with a photo. During a check at the waterside you have them right away.',
          'Bewahre hier deinen Fischereischein und andere Erlaubnisse auf, mit Foto. Bei einer Kontrolle am Wasser hast du sie sofort zur Hand.',
          'Garde ici ton permis et tes autorisations, avec une photo. Lors d’un contrôle au bord de l’eau, tu les as tout de suite.',
          'Guarda aquí tu licencia y otros permisos, con foto. En un control en la orilla los tienes al momento.',
          'Trzymaj tu kartę wędkarską i pozostałe zezwolenia, ze zdjęciem. Przy kontroli nad wodą masz je od razu.')),
    ],
  ),

  // ── 7. Samen vissen ─────────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'sociaal', icoon: '👥',
    naam: tx('Samen vissen', 'Fishing together', 'Gemeinsam angeln', 'Pêcher ensemble', 'Pescar juntos', 'Wędkowanie razem'),
    samenvatting: tx('Albums, berichten en wedstrijden met je vismaten.', 'Albums, messages and contests with your buddies.',
        'Alben, Nachrichten und Wettkämpfe mit deinen Kumpels.', 'Albums, messages et concours avec tes copains.',
        'Álbumes, mensajes y concursos con tus amigos.', 'Albumy, wiadomości i zawody z kolegami.'),
    stappen: [
      Stap(id: 'menu-albums', tab: _tabMenu, zoek: 'menu-albums', optioneel: true,
        titel: tx('Fotoalbums', 'Photo albums', 'Fotoalben', 'Albums photo', 'Álbumes de fotos', 'Albumy zdjęć'),
        tekst: tx(
          'Zet de foto’s van een dag of een trip bij elkaar in een album. Je bepaalt zelf of je het deelt of voor jezelf houdt.',
          'Group the photos from a day or a trip into an album. You decide whether you share it or keep it to yourself.',
          'Fasse die Fotos von einem Tag oder einer Tour in einem Album zusammen. Du entscheidest, ob du es teilst oder für dich behältst.',
          'Regroupe les photos d’une journée ou d’un voyage dans un album. Tu décides de le partager ou de le garder pour toi.',
          'Reúne las fotos de un día o un viaje en un álbum. Tú decides si lo compartes o te lo quedas.',
          'Zbierz zdjęcia z jednego dnia albo wyjazdu w jeden album. Sam decydujesz, czy go udostępnisz.')),
      Stap(id: 'menu-berichten', tab: _tabMenu, zoek: 'menu-berichten', optioneel: true,
        titel: tx('Berichten', 'Messages', 'Nachrichten', 'Messages', 'Mensajes', 'Wiadomości'),
        tekst: tx(
          'Stuur een bericht naar een vismaat, bijvoorbeeld om af te spreken. Schrijft iemand in een andere taal, dan vertaalt de app het voor je.',
          'Send a message to a buddy, for instance to arrange a trip. If someone writes in another language, the app translates it for you.',
          'Schreib einem Angelkumpel, zum Beispiel für eine Verabredung. Schreibt jemand in einer anderen Sprache, übersetzt die App es für dich.',
          'Écris à un copain, par exemple pour convenir d’une sortie. Si quelqu’un écrit dans une autre langue, l’app te le traduit.',
          'Escribe a un compañero, por ejemplo para quedar. Si alguien escribe en otro idioma, la app te lo traduce.',
          'Napisz do kolegi, na przykład żeby się umówić. Jeśli ktoś pisze w innym języku, aplikacja przetłumaczy wiadomość.')),
      Stap(id: 'menu-wedstrijden', tab: _tabMenu, zoek: 'menu-wedstrijden', optioneel: true,
        titel: tx('Wedstrijden', 'Contests', 'Wettkämpfe', 'Concours', 'Concursos', 'Zawody'),
        tekst: tx(
          'Doe mee aan een wedstrijd van YessFish of van een vereniging. Je meldt je aan en je vangsten tellen vanzelf mee zolang de wedstrijd loopt.',
          'Join a contest from YessFish or from a club. You sign up and your catches count automatically while the contest runs.',
          'Mach bei einem Wettkampf von YessFish oder einem Verein mit. Du meldest dich an und deine Fänge zählen automatisch, solange er läuft.',
          'Participe à un concours de YessFish ou d’une association. Tu t’inscris et tes prises comptent automatiquement pendant le concours.',
          'Participa en un concurso de YessFish o de un club. Te inscribes y tus capturas cuentan solas mientras dura.',
          'Weź udział w zawodach YessFish albo klubu. Zapisujesz się, a twoje połowy liczą się same, dopóki zawody trwają.')),
    ],
  ),

  // ── 8. Het menu ─────────────────────────────────────────────────────────────────────────
  Hoofdstuk(
    id: 'menu', icoon: '⚙️',
    naam: tx('Menu en profiel', 'Menu and profile', 'Menü und Profil', 'Menu et profil', 'Menú y perfil', 'Menu i profil'),
    samenvatting: tx('Soortengids, uitrusting, documenten en instellingen.',
        'Species guide, tackle, documents and settings.', 'Artenführer, Ausrüstung, Dokumente und Einstellungen.',
        'Guide des espèces, matériel, documents et réglages.', 'Guía de especies, equipo, documentos y ajustes.',
        'Przewodnik gatunków, sprzęt, dokumenty i ustawienia.'),
    stappen: [
      Stap(id: 'menu-overzicht', tab: _tabMenu,
        titel: tx('Alles bij elkaar', 'All together', 'Alles beisammen', 'Tout au même endroit', 'Todo junto', 'Wszystko razem'),
        tekst: tx(
          'In dit menu staat de rest: je profiel, de soortengids, je uitrusting, je visdocumenten, vismaten, berichten en de instellingen.',
          'This menu holds the rest: your profile, the species guide, your tackle, your fishing documents, buddies, messages and settings.',
          'In diesem Menü steckt der Rest: Profil, Artenführer, Ausrüstung, Angeldokumente, Kumpels, Nachrichten und Einstellungen.',
          'Ce menu contient le reste : profil, guide des espèces, matériel, documents de pêche, copains, messages et réglages.',
          'Este menú tiene el resto: perfil, guía de especies, equipo, documentos de pesca, amigos, mensajes y ajustes.',
          'W tym menu jest reszta: profil, przewodnik gatunków, sprzęt, dokumenty, koledzy, wiadomości i ustawienia.')),
      Stap(id: 'menu-soorten', tab: _tabMenu, zoek: 'menu-soorten', optioneel: true,
        titel: tx('De soortengids', 'The species guide', 'Der Artenführer', 'Le guide des espèces', 'La guía de especies', 'Przewodnik gatunków'),
        tekst: tx(
          'Ruim honderd vissoorten met foto, herkenning, aas en de beste tijd van het jaar. Handig als je niet zeker weet wat je hebt gevangen.',
          'Over a hundred species with photo, identification, bait and the best time of year. Handy when you are not sure what you caught.',
          'Über hundert Arten mit Foto, Bestimmung, Köder und bester Jahreszeit. Praktisch, wenn du nicht sicher bist, was du gefangen hast.',
          'Plus de cent espèces avec photo, identification, appât et meilleure saison. Pratique en cas de doute sur ta prise.',
          'Más de cien especies con foto, identificación, cebo y mejor época. Útil si no sabes qué has pescado.',
          'Ponad sto gatunków ze zdjęciem, rozpoznaniem, przynętą i najlepszą porą. Przydatne, gdy nie wiesz, co złowiłeś.')),
      Stap(id: 'menu-gids', tab: _tabMenu, zoek: 'menu-gids', optioneel: true,
        titel: tx('De gids', 'The guide', 'Der Führer', 'Le guide', 'La guía', 'Przewodnik'),
        tekst: tx(
          'In de gids staan verenigingen, hengelsportwinkels en jachthavens bij elkaar. Zoek op naam of kijk wat er bij jou in de buurt zit.',
          'The guide lists clubs, tackle shops and marinas together. Search by name or see what is near you.',
          'Im Führer stehen Vereine, Angelläden und Marinas beisammen. Such nach Namen oder schau, was in deiner Nähe ist.',
          'Le guide réunit associations, magasins de pêche et ports. Cherche par nom ou regarde ce qu’il y a près de chez toi.',
          'La guía reúne clubes, tiendas de pesca y puertos. Busca por nombre o mira qué hay cerca de ti.',
          'W przewodniku znajdziesz kluby, sklepy wędkarskie i mariny. Szukaj po nazwie albo zobacz, co jest w pobliżu.')),
      Stap(id: 'menu-mijndata', tab: _tabMenu, zoek: 'menu-mijndata', optioneel: true,
        titel: tx('Je eigen gegevens', 'Your own data', 'Deine eigenen Daten', 'Tes données', 'Tus datos', 'Twoje dane'),
        tekst: tx(
          'Hier vraag je een kopie op van alles wat we van je bewaren, of laat je je gegevens wissen. Je vangsten en foto’s blijven van jou.',
          'Here you request a copy of everything we keep about you, or have your data erased. Your catches and photos stay yours.',
          'Hier forderst du eine Kopie von allem an, was wir von dir speichern, oder lässt deine Daten löschen. Deine Fänge und Fotos bleiben deine.',
          'Ici tu demandes une copie de tout ce qu’on garde sur toi, ou tu fais effacer tes données. Tes prises et tes photos restent les tiennes.',
          'Aquí pides una copia de todo lo que guardamos de ti, o haces que borren tus datos. Tus capturas y fotos siguen siendo tuyas.',
          'Tu poprosisz o kopię wszystkiego, co o tobie przechowujemy, albo o usunięcie danych. Twoje połowy i zdjęcia zostają twoje.')),
      Stap(id: 'menu-instellingen', tab: _tabMenu, zoek: 'menu-instellingen', optioneel: true,
        titel: tx('Instellingen', 'Settings', 'Einstellungen', 'Réglages', 'Ajustes', 'Ustawienia'),
        tekst: tx(
          'Hier stel je je taal in, of je in centimeters of inches werkt, en welke meldingen je wilt krijgen.',
          'Here you set your language, whether you work in centimetres or inches, and which notifications you want.',
          'Hier stellst du deine Sprache ein, ob du in Zentimetern oder Zoll rechnest, und welche Meldungen du bekommst.',
          'Ici tu règles ta langue, les centimètres ou les pouces, et les notifications que tu veux recevoir.',
          'Aquí eliges tu idioma, si trabajas en centímetros o pulgadas, y qué avisos quieres recibir.',
          'Tu ustawisz język, centymetry albo cale, oraz powiadomienia, które chcesz dostawać.')),
      Stap(id: 'menu-wedstrijd', tab: _tabMenu, zoek: 'menu-wedstrijd', optioneel: true,
        titel: tx('De wedstrijd', 'The contest', 'Der Wettbewerb', 'Le concours', 'El concurso', 'Konkurs'),
        tekst: tx(
          'Verdien punten met vangsten, stekken en nieuwe wateren, en klim in de ranglijst. In onze video’s noemen we soms een geheim woord — dat vul je hier in voor extra punten.',
          'Earn points with catches, spots and new waters, and climb the ranking. Our videos sometimes mention a secret word — enter it here for extra points.',
          'Sammle Punkte mit Fängen, Stellen und neuen Gewässern und klettere im Ranking. In unseren Videos fällt manchmal ein geheimes Wort — das trägst du hier ein.',
          'Gagne des points avec tes prises, tes spots et de nouvelles eaux, et grimpe au classement. Nos vidéos donnent parfois un mot secret — saisis-le ici.',
          'Gana puntos con capturas, puntos y aguas nuevas, y sube en la clasificación. En nuestros vídeos a veces decimos una palabra secreta — escríbela aquí.',
          'Zdobywaj punkty za połowy, stanowiska i nowe wody i piń się w rankingu. W naszych filmach pada czasem tajne słowo — wpisz je tutaj.')),
      Stap(id: 'menu-schone-stek', tab: _tabMenu, zoek: 'menu-schone-stek', optioneel: true,
        titel: tx('Houd je stek schoon', 'Keep your spot clean', 'Halte deine Stelle sauber', 'Garde ton spot propre', 'Mantén limpio tu sitio', 'Utrzymuj stanowisko w czystości'),
        tekst: tx(
          'Maak bij aankomst een foto van je plek en bij vertrek nog een. Daar verdien je punten en een badge mee. De foto maak je ter plekke met de camera — uit je galerij kan niet.',
          'Take a photo of your spot when you arrive and another when you leave. That earns points and a badge. The photo is taken on the spot with the camera — not from your gallery.',
          'Mach bei Ankunft ein Foto deiner Stelle und beim Gehen noch eins. Das bringt Punkte und ein Abzeichen. Das Foto entsteht vor Ort mit der Kamera — nicht aus der Galerie.',
          'Prends une photo de ton spot en arrivant et une autre en partant. Ça rapporte des points et un badge. La photo se prend sur place avec l’appareil — pas depuis la galerie.',
          'Haz una foto de tu sitio al llegar y otra al irte. Eso da puntos y una insignia. La foto se hace allí con la cámara — no desde la galería.',
          'Zrób zdjęcie stanowiska po przyjściu i drugie przy wyjściu. To daje punkty i odznakę. Zdjęcie robisz na miejscu aparatem — nie z galerii.')),
      Stap(id: 'menu-winacties', tab: _tabMenu, zoek: 'menu-winacties', optioneel: true,
        titel: tx('Winacties', 'Giveaways', 'Gewinnspiele', 'Jeux-concours', 'Sorteos', 'Konkursy'),
        tekst: tx(
          'Winkels en verenigingen zetten hier weleens iets te winnen neer. Je ziet wie het geeft, tot wanneer het loopt en wat de voorwaarden zijn.',
          'Shops and clubs sometimes put something up for grabs here. You see who gives it, how long it runs and the terms.',
          'Läden und Vereine stellen hier manchmal etwas zu gewinnen ein. Du siehst, wer es gibt, wie lange es läuft und die Bedingungen.',
          'Magasins et associations proposent parfois quelque chose à gagner ici. Tu vois qui l’offre, jusqu’à quand et les conditions.',
          'Tiendas y clubes a veces ponen algo para ganar aquí. Ves quién lo ofrece, hasta cuándo y las condiciones.',
          'Sklepy i kluby czasem wystawiają tu coś do wygrania. Widzisz, kto daje, do kiedy trwa i jakie są warunki.')),
      Stap(id: 'menu-einde', tab: _tabMenu,
        titel: tx('Dat was hem', 'That is it', 'Das war’s', 'C’est tout', 'Eso es todo', 'To wszystko'),
        tekst: tx(
          'Je hebt de rondleiding gehad. Je kunt hem altijd opnieuw starten via het menu. Veel visplezier!',
          'You have completed the tour. You can start it again any time from the menu. Tight lines!',
          'Du hast die Tour abgeschlossen. Du kannst sie jederzeit im Menü neu starten. Petri Heil!',
          'Tu as terminé la visite. Tu peux la relancer depuis le menu. Bonne pêche !',
          'Has terminado el recorrido. Puedes reiniciarlo desde el menú. ¡Buena pesca!',
          'Ukończyłeś przewodnik. Możesz go uruchomić ponownie z menu. Udanych połowów!')),
    ],
  ),
];

/// Alle stappen achter elkaar, in de volgorde van de hoofdstukken.
List<Stap> alleStappen() => [for (final h in hoofdstukken) ...h.stappen];
