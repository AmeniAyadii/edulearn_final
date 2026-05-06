// lib/games/guess_game/data/objects_database.dart

import 'dart:math';

import 'package:edulearn_final/models/game_session.dart';
import 'package:flutter/material.dart';


class GameObjectsDatabase {
  // Liste complète des objets par catégorie
  static final List<GameObject> allObjects = [
    // ==================== ANIMAUX (12 objets) ====================
    GameObject(
      id: 1,
      name: 'chat',
      displayName: 'Chat',
      difficulty: Difficulty.easy,
      clues: [
        '🐱 Cet animal fait "miaou"',
        '🥛 Il adore boire du lait',
        '🐭 Il est connu pour chasser les souris',
        '😴 Il dort environ 16 heures par jour',
        '🐾 Il a des griffes rétractables',
      ],
      emoji: '🐱',
      pointsBonus: 10,
    ),
    GameObject(
      id: 2,
      name: 'chien',
      displayName: 'Chien',
      difficulty: Difficulty.easy,
      clues: [
        '🐶 C\'est le meilleur ami de l\'homme',
        '🗣️ Il aboie pour prévenir les intrus',
        '🦴 Il adore jouer et manger des os',
        '🐕 Il peut être de différentes races',
        '🎾 Il aime rapporter la balle',
      ],
      emoji: '🐶',
      pointsBonus: 10,
    ),
    GameObject(
      id: 3,
      name: 'oiseau',
      displayName: 'Oiseau',
      difficulty: Difficulty.easy,
      clues: [
        '🦜 Cet animal vole dans le ciel',
        '🥚 Il pond des œufs',
        '🎵 Il chante le matin',
        '🪹 Il construit des nids dans les arbres',
        '🦅 Certaines espèces migrent en hiver',
      ],
      emoji: '🐦',
      pointsBonus: 10,
    ),
    GameObject(
      id: 4,
      name: 'poisson',
      displayName: 'Poisson',
      difficulty: Difficulty.easy,
      clues: [
        '🐟 Cet animal vit dans l\'eau',
        '🌊 Il respire avec des branchies',
        '🐠 Il nage dans un aquarium',
        '🎣 On peut le pêcher',
        '🐡 Certains ont des couleurs vives',
      ],
      emoji: '🐟',
      pointsBonus: 10,
    ),
    GameObject(
      id: 5,
      name: 'lapin',
      displayName: 'Lapin',
      difficulty: Difficulty.easy,
      clues: [
        '🐰 Cet animal a de longues oreilles',
        '🥕 Il adore les carottes',
        '🐇 Il saute très haut',
        '🍂 Il vit dans un terrier',
        '🐣 Il a une queue toute ronde',
      ],
      emoji: '🐰',
      pointsBonus: 10,
    ),
    GameObject(
      id: 6,
      name: 'cheval',
      displayName: 'Cheval',
      difficulty: Difficulty.medium,
      clues: [
        '🐴 Cet animal court très vite',
        '🌾 Il mange du foin et de l\'herbe',
        '🏇 On peut le monter',
        '👞 Il porte des fers aux pieds',
        '🏆 Il participe à des courses',
      ],
      emoji: '🐴',
      pointsBonus: 15,
    ),
    GameObject(
      id: 7,
      name: 'vache',
      displayName: 'Vache',
      difficulty: Difficulty.easy,
      clues: [
        '🐮 Cet animal donne du lait',
        '🌿 Elle vit dans les champs',
        '🔔 Elle porte une cloche au cou',
        '🧀 On fait du fromage avec son lait',
        '🐄 Elle fait "meuh"',
      ],
      emoji: '🐮',
      pointsBonus: 10,
    ),
    GameObject(
      id: 8,
      name: 'cochon',
      displayName: 'Cochon',
      difficulty: Difficulty.easy,
      clues: [
        '🐷 Cet animal a le nez rond',
        '🌾 Il mange tout ce qu\'on lui donne',
        '💕 Sa couleur est souvent rose',
        '🥓 On fait du jambon avec',
        '🐖 Il adore se vautrer dans la boue',
      ],
      emoji: '🐷',
      pointsBonus: 10,
    ),
    GameObject(
      id: 9,
      name: 'singe',
      displayName: 'Singe',
      difficulty: Difficulty.medium,
      clues: [
        '🐒 Cet animal adore les bananes',
        '🌴 Il vit dans la jungle',
        '🧗 Il grimpe aux arbres',
        '🍌 Il a une longue queue',
        '😄 Il imite les humains',
      ],
      emoji: '🐒',
      pointsBonus: 15,
    ),
    GameObject(
      id: 10,
      name: 'souris',
      displayName: 'Souris',
      difficulty: Difficulty.easy,
      clues: [
        '🐭 Ce petit animal grignote du fromage',
        '🏠 Il vit parfois dans les maisons',
        '🐱 Le chat est son prédateur',
        '🔊 Il couine',
        '🧀 Il est très petit',
      ],
      emoji: '🐭',
      pointsBonus: 10,
    ),
    GameObject(
      id: 11,
      name: 'abeille',
      displayName: 'Abeille',
      difficulty: Difficulty.medium,
      clues: [
        '🐝 Cet insecte produit du miel',
        '🌸 Elle butine les fleurs',
        '🏠 Elle vit dans une ruche',
        '🍯 Elle fait du miel délicieux',
        '⚠️ Elle peut piquer',
      ],
      emoji: '🐝',
      pointsBonus: 15,
    ),
    GameObject(
      id: 12,
      name: 'papillon',
      displayName: 'Papillon',
      difficulty: Difficulty.easy,
      clues: [
        '🦋 Cet insecte a des ailes colorées',
        '🌸 Il vole autour des fleurs',
        '🐛 Il était une chenille avant',
        '🌈 Ses ailes sont belles',
        '☀️ Il aime le soleil',
      ],
      emoji: '🦋',
      pointsBonus: 10,
    ),

    // ==================== FRUITS & LÉGUMES (10 objets) ====================
    GameObject(
      id: 13,
      name: 'pomme',
      displayName: 'Pomme',
      difficulty: Difficulty.easy,
      clues: [
        '🍎 Ce fruit est rouge ou vert',
        '🌳 Il pousse sur un arbre',
        '🥧 On fait de la tarte avec',
        '👨‍⚕️ Une pomme par jour éloigne le médecin',
        '🍏 Il existe aussi des pommes vertes',
      ],
      emoji: '🍎',
      pointsBonus: 10,
    ),
    GameObject(
      id: 14,
      name: 'banane',
      displayName: 'Banane',
      difficulty: Difficulty.easy,
      clues: [
        '🍌 Ce fruit est jaune et courbé',
        '🐒 Les singes l\'adorent',
        '🌴 Il pousse en grappe',
        '💛 Il est plein de potassium',
        '🥛 On peut faire des smoothies avec',
      ],
      emoji: '🍌',
      pointsBonus: 10,
    ),
    GameObject(
      id: 15,
      name: 'fraise',
      displayName: 'Fraise',
      difficulty: Difficulty.easy,
      clues: [
        '🍓 Ce fruit est petit et rouge',
        '🌱 Il pousse près du sol',
        '🍰 On le met sur les gâteaux',
        '❤️ Il a la forme d\'un cœur',
        '🍬 On fait des bonbons à la fraise',
      ],
      emoji: '🍓',
      pointsBonus: 10,
    ),
    GameObject(
      id: 16,
      name: 'orange',
      displayName: 'Orange',
      difficulty: Difficulty.easy,
      clues: [
        '🍊 Ce fruit est rond et orange',
        '🧃 On fait du jus avec',
        '🌳 Il pousse sur un arbre',
        '🍊 Il est plein de vitamine C',
        '🥧 On peut faire de la confiture',
      ],
      emoji: '🍊',
      pointsBonus: 10,
    ),
    GameObject(
      id: 17,
      name: 'raisin',
      displayName: 'Raisin',
      difficulty: Difficulty.medium,
      clues: [
        '🍇 Ce fruit pousse en grappe',
        '🍷 On fait du vin avec',
        '🌿 Il peut être vert ou violet',
        '🍇 Il est sucré',
        '🥧 On le mange frais ou en confiture',
      ],
      emoji: '🍇',
      pointsBonus: 15,
    ),
    GameObject(
      id: 18,
      name: 'cerise',
      displayName: 'Cerise',
      difficulty: Difficulty.medium,
      clues: [
        '🍒 Ce petit fruit rouge a un noyau',
        '🌳 Il pousse sur un arbre',
        '🥧 On fait des clafoutis',
        '❤️ Il est souvent en forme de cœur',
        '🍒 Deux cerises c\'est le symbole',
      ],
      emoji: '🍒',
      pointsBonus: 15,
    ),
    GameObject(
      id: 19,
      name: 'carotte',
      displayName: 'Carotte',
      difficulty: Difficulty.easy,
      clues: [
        '🥕 Ce légume est orange',
        '🐰 Les lapins l\'adorent',
        '🌱 Il pousse sous terre',
        '🥗 On la mange crue ou cuite',
        '👀 Elle est bonne pour les yeux',
      ],
      emoji: '🥕',
      pointsBonus: 10,
    ),
    GameObject(
      id: 20,
      name: 'tomate',
      displayName: 'Tomate',
      difficulty: Difficulty.medium,
      clues: [
        '🍅 Ce légume-fruit est rouge',
        '🍝 On fait de la sauce avec',
        '🥗 Elle est bonne dans la salade',
        '🌞 Elle pousse en été',
        '🍅 On peut la farcir',
      ],
      emoji: '🍅',
      pointsBonus: 15,
    ),
    GameObject(
      id: 21,
      name: 'citron',
      displayName: 'Citron',
      difficulty: Difficulty.medium,
      clues: [
        '🍋 Ce fruit est jaune et acide',
        '🍋 On le met dans l’eau',
        '🥧 On fait des tartes au citron',
        '🧴 Son jus nettoie',
        '🍋 Il est très vitaminé',
      ],
      emoji: '🍋',
      pointsBonus: 15,
    ),
    GameObject(
      id: 22,
      name: 'melon',
      displayName: 'Melon',
      difficulty: Difficulty.hard,
      clues: [
        '🍈 Ce fruit est vert à l\'extérieur, orange dedans',
        '🌞 Il est très juteux en été',
        '🍈 Il a des graines au centre',
        '🥗 On le mange en entrée ou dessert',
        '🍈 Sa peau est épaisse',
      ],
      emoji: '🍈',
      pointsBonus: 20,
    ),

    // ==================== VÉHICULES (8 objets) ====================
    GameObject(
      id: 23,
      name: 'voiture',
      displayName: 'Voiture',
      difficulty: Difficulty.medium,
      clues: [
        '🚗 Ce véhicule a 4 roues',
        '⛽ Il a besoin d\'essence pour rouler',
        '🔑 On le conduit avec un volant',
        '🚦 Il doit respecter les feux',
        '🚙 Il sert à se déplacer',
      ],
      emoji: '🚗',
      pointsBonus: 15,
    ),
    GameObject(
      id: 24,
      name: 'vélo',
      displayName: 'Vélo',
      difficulty: Difficulty.easy,
      clues: [
        '🚲 Ce véhicule a 2 roues',
        '🦵 On le pédale avec les pieds',
        '🚴 Il est écologique',
        '🏆 Il fait du sport',
        '🚲 On le gare sur un support',
      ],
      emoji: '🚲',
      pointsBonus: 10,
    ),
    GameObject(
      id: 25,
      name: 'avion',
      displayName: 'Avion',
      difficulty: Difficulty.medium,
      clues: [
        '✈️ Ce véhicule vole dans le ciel',
        '🛫 Il décolle d’un aéroport',
        '🛬 Il atterrit après le vol',
        '☁️ Il traverse les nuages',
        '🌍 Il sert à voyager loin',
      ],
      emoji: '✈️',
      pointsBonus: 15,
    ),
    GameObject(
      id: 26,
      name: 'train',
      displayName: 'Train',
      difficulty: Difficulty.medium,
      clues: [
        '🚂 Ce véhicule roule sur des rails',
        '🚆 Il est très long',
        '🔔 Il fait "tchou tchou"',
        '🛤️ Il a besoin de voies ferrées',
        '🚉 Il s’arrête en gare',
      ],
      emoji: '🚂',
      pointsBonus: 15,
    ),
    GameObject(
      id: 27,
      name: 'bateau',
      displayName: 'Bateau',
      difficulty: Difficulty.medium,
      clues: [
        '⛵ Ce véhicule flotte sur l’eau',
        '🌊 Il navigue sur la mer',
        '⚓ Il jette l’ancre pour s’arrêter',
        '🚤 Il peut être à moteur',
        '🎣 On peut pêcher dessus',
      ],
      emoji: '⛵',
      pointsBonus: 15,
    ),
    GameObject(
      id: 28,
      name: 'hélicoptère',
      displayName: 'Hélicoptère',
      difficulty: Difficulty.hard,
      clues: [
        '🚁 Cet appareil a des pales sur le toit',
        '🛩️ Il peut voler sur place',
        '🚁 Il sert souvent aux secours',
        '🏔️ Il peut atterrir en montagne',
        '🚁 Il fait beaucoup de bruit',
      ],
      emoji: '🚁',
      pointsBonus: 20,
    ),
    GameObject(
      id: 29,
      name: 'moto',
      displayName: 'Moto',
      difficulty: Difficulty.medium,
      clues: [
        '🏍️ Ce véhicule a 2 roues comme le vélo',
        '⛽ Il roule à l’essence',
        '🏍️ Il est plus rapide qu’un vélo',
        '🛵 On peut porter un casque',
        '🏁 On fait des courses avec',
      ],
      emoji: '🏍️',
      pointsBonus: 15,
    ),
    GameObject(
      id: 30,
      name: 'camion',
      displayName: 'Camion',
      difficulty: Difficulty.medium,
      clues: [
        '🚛 Ce gros véhicule transporte des marchandises',
        '📦 Il a une grande remorque',
        '🚚 Il livre dans les magasins',
        '⛽ Il consomme beaucoup d’essence',
        '🚛 On voit son logo sur l’autoroute',
      ],
      emoji: '🚛',
      pointsBonus: 15,
    ),

    // ==================== OBJETS DE LA MAISON (15 objets) ====================
    GameObject(
      id: 31,
      name: 'chaise',
      displayName: 'Chaise',
      difficulty: Difficulty.medium,
      clues: [
        '🪑 Meuble sur lequel on s’assoit',
        '🏠 On la trouve dans la salle à manger',
        '4️⃣ Elle a généralement 4 pieds',
        '🍽️ On s’assoit dessus pour manger',
        '🪑 Elle a un dossier',
      ],
      emoji: '🪑',
      pointsBonus: 15,
    ),
    GameObject(
      id: 32,
      name: 'table',
      displayName: 'Table',
      difficulty: Difficulty.medium,
      clues: [
        '🪵 Meuble sur lequel on pose les assiettes',
        '🏠 Dans la salle à manger',
        '🍽️ Entourée de chaises',
        '🪚 Elle est souvent en bois',
        '🍲 On y mange les repas',
      ],
      emoji: '🪑',
      pointsBonus: 15,
    ),
    GameObject(
      id: 33,
      name: 'lit',
      displayName: 'Lit',
      difficulty: Difficulty.medium,
      clues: [
        '🛏️ Meuble sur lequel on dort',
        '🛌 Il est moelleux',
        '🌙 Dans la chambre à coucher',
        '🛏️ On met des draps dessus',
        '💤 Il sert à se reposer',
      ],
      emoji: '🛏️',
      pointsBonus: 15,
    ),
    GameObject(
      id: 34,
      name: 'livre',
      displayName: 'Livre',
      difficulty: Difficulty.easy,
      clues: [
        '📖 Objet avec beaucoup de pages',
        '📚 On le lit pour apprendre',
        '🔖 On le range dans une bibliothèque',
        '📖 Il a une couverture',
        '📘 Il peut être une histoire',
      ],
      emoji: '📖',
      pointsBonus: 10,
    ),
    GameObject(
      id: 35,
      name: 'stylo',
      displayName: 'Stylo',
      difficulty: Difficulty.easy,
      clues: [
        '✍️ Objet qui sert à écrire',
        '🖊️ Il contient de l’encre',
        '📝 On le tient à la main',
        '🖋️ Il peut être bleu ou noir',
        '📓 On écrit dans un cahier avec',
      ],
      emoji: '✍️',
      pointsBonus: 10,
    ),
    GameObject(
      id: 36,
      name: 'téléphone',
      displayName: 'Téléphone',
      difficulty: Difficulty.medium,
      clues: [
        '📱 Objet qui sert à communiquer',
        '📞 On peut appeler avec',
        '💬 Il sert aussi à envoyer des messages',
        '📸 Il a un appareil photo',
        '🌐 Il permet d’aller sur Internet',
      ],
      emoji: '📱',
      pointsBonus: 15,
    ),
    GameObject(
      id: 37,
      name: 'ordinateur',
      displayName: 'Ordinateur',
      difficulty: Difficulty.hard,
      clues: [
        '💻 Machine qui sert à travailler',
        '🖥️ Elle a un écran',
        '⌨️ On utilise un clavier avec',
        '🖱️ On a une souris',
        '🌍 On peut aller sur Internet',
      ],
      emoji: '💻',
      pointsBonus: 20,
    ),
    GameObject(
      id: 38,
      name: 'télévision',
      displayName: 'Télévision',
      difficulty: Difficulty.medium,
      clues: [
        '📺 Écran où on regarde des dessins animés',
        '📡 On capte les chaînes avec une antenne',
        '🎬 On peut voir des films',
        '🕹️ On peut brancher une console',
        '📺 Elle est dans le salon',
      ],
      emoji: '📺',
      pointsBonus: 15,
    ),
    GameObject(
      id: 39,
      name: 'lampe',
      displayName: 'Lampe',
      difficulty: Difficulty.medium,
      clues: [
        '💡 Objet qui éclaire la pièce',
        '🔘 On l’allume avec un bouton',
        '💡 Elle peut être sur un bureau',
        '🕯️ Il y a une ampoule dedans',
        '🌙 Elle sert la nuit',
      ],
      emoji: '💡',
      pointsBonus: 15,
    ),
    GameObject(
      id: 40,
      name: 'réfrigérateur',
      displayName: 'Réfrigérateur',
      difficulty: Difficulty.hard,
      clues: [
        '🧊 Gros appareil qui garde les aliments au froid',
        '🥛 On y met le lait et les œufs',
        '❄️ Il fait du froid à l’intérieur',
        '🚪 On l’ouvre pour prendre à manger',
        '🍦 On y garde les glaces',
      ],
      emoji: '🧊',
      pointsBonus: 20,
    ),
    GameObject(
      id: 41,
      name: 'four',
      displayName: 'Four',
      difficulty: Difficulty.hard,
      clues: [
        '🔥 Appareil de cuisine qui chauffe',
        '🍕 On y fait cuire des pizzas',
        '🥧 On peut faire des gâteaux',
        '🍗 Il sert à rôtir la viande',
        '🍪 On y cuit des biscuits',
      ],
      emoji: '🔥',
      pointsBonus: 20,
    ),
    GameObject(
      id: 42,
      name: 'aspirateur',
      displayName: 'Aspirateur',
      difficulty: Difficulty.hard,
      clues: [
        '🧹 Appareil qui aspire la poussière',
        '🔌 On le branche sur secteur',
        '🧵 Il a un long tube',
        '🏠 On nettoie la maison avec',
        '🗑️ Il aspire les miettes',
      ],
      emoji: '🧹',
      pointsBonus: 20,
    ),
    GameObject(
      id: 43,
      name: 'montre',
      displayName: 'Montre',
      difficulty: Difficulty.medium,
      clues: [
        '⌚ Petit objet qu’on porte au poignet',
        '⏰ Elle indique l’heure',
        '🔋 Elle peut être à pile',
        '🏃 On la porte pour le sport',
        '📟 Elle peut être numérique',
      ],
      emoji: '⌚',
      pointsBonus: 15,
    ),
    GameObject(
      id: 44,
      name: 'lunettes',
      displayName: 'Lunettes',
      difficulty: Difficulty.medium,
      clues: [
        '👓 Objet qui aide à mieux voir',
        '☀️ Les lunettes de soleil protègent du soleil',
        '👀 Elles ont deux verres',
        '🕶️ Certaines sont noires',
        '📖 On les porte pour lire',
      ],
      emoji: '👓',
      pointsBonus: 15,
    ),
    GameObject(
      id: 45,
      name: 'couteau',
      displayName: 'Couteau',
      difficulty: Difficulty.medium,
      clues: [
        '🔪 Objet tranchant de la cuisine',
        '🍞 Il sert à couper le pain',
        '🍅 On coupe les légumes avec',
        '🍴 Il est dangereux',
        '🗡️ Il a une lame',
      ],
      emoji: '🔪',
      pointsBonus: 15,
    ),

    // ==================== NATURE (5 objets) ====================
    GameObject(
      id: 46,
      name: 'fleur',
      displayName: 'Fleur',
      difficulty: Difficulty.easy,
      clues: [
        '🌸 Plante qui a des pétales colorés',
        '🌻 Elle tourne vers le soleil',
        '🐝 Les abeilles butinent son pollen',
        '🎁 On l’offre pour faire plaisir',
        '🌷 Elle pousse au printemps',
      ],
      emoji: '🌸',
      pointsBonus: 10,
    ),
    GameObject(
      id: 47,
      name: 'arbre',
      displayName: 'Arbre',
      difficulty: Difficulty.medium,
      clues: [
        '🌳 Grande plante avec un tronc et des branches',
        '🍎 Il donne des fruits',
        '🍂 Il perd ses feuilles en automne',
        '🌲 On fait du bois avec',
        '🏠 On peut grimper dedans',
      ],
      emoji: '🌳',
      pointsBonus: 15,
    ),
    GameObject(
      id: 48,
      name: 'soleil',
      displayName: 'Soleil',
      difficulty: Difficulty.easy,
      clues: [
        '☀️ Grosse étoile qui nous éclaire le jour',
        '🌞 Il donne de la chaleur',
        '😎 On met des lunettes pour le regarder',
        '🌍 La Terre tourne autour',
        '🏖️ On se baigne quand il brille',
      ],
      emoji: '☀️',
      pointsBonus: 10,
    ),
    GameObject(
      id: 49,
      name: 'lune',
      displayName: 'Lune',
      difficulty: Difficulty.medium,
      clues: [
        '🌙  Satellite qui brille la nuit',
        '🌕 Elle change de forme',
        '🚀 Les astronautes y sont allés',
        '🌜 Elle éclaire sans faire de chaleur',
        '🐺 Les loups hurlent devant elle',
      ],
      emoji: '🌙',
      pointsBonus: 15,
    ),
    GameObject(
      id: 50,
      name: 'étoile',
      displayName: 'Étoile',
      difficulty: Difficulty.medium,
      clues: [
        '⭐ Petit point brillant dans le ciel la nuit',
        '✨ On en voit des milliers',
        '🔭 Elles sont très loin',
        '🌟 La plus proche est le Soleil',
        '⭐ On fait des vœux en la voyant',
      ],
      emoji: '⭐',
      pointsBonus: 15,
    ),

    // ==================== NOURRITURE (5 objets) ====================
    GameObject(
      id: 51,
      name: 'pain',
      displayName: 'Pain',
      difficulty: Difficulty.easy,
      clues: [
        '🥖 Aliment fait de farine et d’eau',
        '🍞 On le mange au petit-déjeuner',
        '🥐 Il peut être en baguette',
        '🧈 On met du beurre dessus',
        '🍞 Il sert à faire des sandwichs',
      ],
      emoji: '🍞',
      pointsBonus: 10,
    ),
    GameObject(
      id: 52,
      name: 'pizza',
      displayName: 'Pizza',
      difficulty: Difficulty.medium,
      clues: [
        '🍕 Plat rond avec de la sauce tomate',
        '🧀 On met du fromage dessus',
        '🍅 Elle peut avoir des légumes',
        '🍖 On peut ajouter du jambon',
        '🔥 Elle cuit au four',
      ],
      emoji: '🍕',
      pointsBonus: 15,
    ),
    GameObject(
      id: 53,
      name: 'glace',
      displayName: 'Glace',
      difficulty: Difficulty.easy,
      clues: [
        '🍦 Dessert qui fond si on la laisse dehors',
        '🍨 Elle est froide et sucrée',
        '🍦 On la mange dans un cornet',
        '🥄 On la prend avec une cuillère',
        '☀️ On l’adore en été',
      ],
      emoji: '🍦',
      pointsBonus: 10,
    ),
    GameObject(
      id: 54,
      name: 'chocolat',
      displayName: 'Chocolat',
      difficulty: Difficulty.medium,
      clues: [
        '🍫 Friandise brune qui fond dans la bouche',
        '🍬 On le mange en tablette',
        '🥛 Le chocolat chaud se boit',
        '🍰 On le met dans les gâteaux',
        '🐣 Il y a des œufs en chocolat à Pâques',
      ],
      emoji: '🍫',
      pointsBonus: 15,
    ),
    GameObject(
      id: 55,
      name: 'œuf',
      displayName: 'Œuf',
      difficulty: Difficulty.medium,
      clues: [
        '🥚 Aliment avec une coquille',
        '🐣 Un poussin peut en sortir',
        '🍳 On le fait cuire à la poêle',
        '🥚 On le casse pour le cuisiner',
        '🐰 Les cloches en apportent à Pâques',
      ],
      emoji: '🥚',
      pointsBonus: 15,
    ),
  ];

  // Méthodes utilitaires
  static List<GameObject> getObjectsByDifficulty(Difficulty difficulty) {
    return allObjects.where((obj) => obj.difficulty == difficulty).toList();
  }

  static List<GameObject> getEasyObjects() {
    return getObjectsByDifficulty(Difficulty.easy);
  }

  static List<GameObject> getMediumObjects() {
    return getObjectsByDifficulty(Difficulty.medium);
  }

  static List<GameObject> getHardObjects() {
    return getObjectsByDifficulty(Difficulty.hard);
  }

  static GameObject getRandomObject() {
    final random = Random();
    return allObjects[random.nextInt(allObjects.length)];
  }

  static GameObject getRandomObjectByDifficulty(Difficulty difficulty) {
    final objects = getObjectsByDifficulty(difficulty);
    final random = Random();
    return objects[random.nextInt(objects.length)];
  }

  static int getTotalObjects() {
    return allObjects.length;
  }

  static Map<Difficulty, int> getCountByDifficulty() {
    return {
      Difficulty.easy: getEasyObjects().length,
      Difficulty.medium: getMediumObjects().length,
      Difficulty.hard: getHardObjects().length,
    };
  }

  // Ajoutez ces méthodes à GameObjectsDatabase

static List<GameObject> getAnimals() {
  return allObjects.where((obj) => 
    obj.name == 'chat' || obj.name == 'chien' || obj.name == 'oiseau' ||
    obj.name == 'poisson' || obj.name == 'lapin' || obj.name == 'cheval' ||
    obj.name == 'vache' || obj.name == 'cochon' || obj.name == 'lion' ||
    obj.name == 'tigre' || obj.name == 'girafe' || obj.name == 'éléphant' ||
    obj.name == 'singe' || obj.name == 'panda' || obj.name == 'dauphin' ||
    obj.name == 'baleine' || obj.name == 'abeille' || obj.name == 'papillon'
  ).toList();
}

static List<GameObject> getFruits() {
  return allObjects.where((obj) =>
    obj.name == 'pomme' || obj.name == 'banane' || obj.name == 'fraise' ||
    obj.name == 'orange' || obj.name == 'citron' || obj.name == 'raisin' ||
    obj.name == 'cerise' || obj.name == 'pastèque' || obj.name == 'ananas' ||
    obj.name == 'mangue' || obj.name == 'kiwi'
  ).toList();
}

static List<GameObject> getVehicles() {
  return allObjects.where((obj) =>
    obj.name == 'voiture' || obj.name == 'vélo' || obj.name == 'moto' ||
    obj.name == 'camion' || obj.name == 'avion' || obj.name == 'train' ||
    obj.name == 'bateau' || obj.name == 'hélicoptère'
  ).toList();
}

static List<GameObject> getHouseObjects() {
  return allObjects.where((obj) =>
    obj.name == 'chaise' || obj.name == 'table' || obj.name == 'lit' ||
    obj.name == 'livre' || obj.name == 'stylo' || obj.name == 'téléphone' ||
    obj.name == 'ordinateur' || obj.name == 'télévision' || obj.name == 'lampe' ||
    obj.name == 'réfrigérateur' || obj.name == 'four' || obj.name == 'couteau'
  ).toList();
}

static List<GameObject> getNatureObjects() {
  return allObjects.where((obj) =>
    obj.name == 'fleur' || obj.name == 'arbre' || obj.name == 'soleil' ||
    obj.name == 'lune' || obj.name == 'étoile'
  ).toList();
}

static List<GameObject> getFoodObjects() {
  return allObjects.where((obj) =>
    obj.name == 'pain' || obj.name == 'pizza' || obj.name == 'glace' ||
    obj.name == 'chocolat' || obj.name == 'hamburger' || obj.name == 'frites' ||
    obj.name == 'pâtes' || obj.name == 'riz'
  ).toList();
}
}

class GameObject {
  final int id;
  final String name;
  final String displayName;
  final Difficulty difficulty;
  final List<String> clues;
  final String emoji;
  final int pointsBonus;

  GameObject({
    required this.id,
    required this.name,
    required this.displayName,
    required this.difficulty,
    required this.clues,
    required this.emoji,
    this.pointsBonus = 0,
  });
}