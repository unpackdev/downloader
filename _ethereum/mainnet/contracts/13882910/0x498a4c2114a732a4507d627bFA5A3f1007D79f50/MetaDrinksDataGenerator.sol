// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaDrinksTypes.sol";
import "./MetaDrinksUtils.sol";

contract MetaDrinksDataGenerator {
    // names
    string[100] internal namesListA = ["Charming", "Brave", "True", "Rapid", "Neat", "Selfish", "Holistic", "Epic", "Speedy", "Aped", "Everyday", "Deep", "Mad", "Crypto", "Lucid", "Gloomy", "Golden", "Endless", "Freaky", "Noble", "a.k.a.", "Broken", "Popular", "Juicy", "Slow", "Viral", "Dynamic", "Organic", "Static", "Elegant", "Next", "Virtual", "Hi-fi", "Poetical", "Graphic", "Tactical", "Good Ol'", "High-end", "Innocent", "Fabulous", "Guilty", "Tantric", "Kinky", "Supreme", "Original", "8-bit", "Horny", "Custom", "Atomic", "Nuclear", "Smooth", "Random", "Healthy", "Kinetic", "Sexy", "Cagey", "Indie", "Lord of", "Gothic", "Iconic", "Last", "Final", "Surreal", "Rare", "Little", "Volatile", "Real", "Vague", "Instant", "Silky", "Neon", "Large", "Happy", "Velvet", "Cosy", "Neo", "Stormy", "Hazy", "Mindful", "Power of", "Wireless", "Sugary", "Ethereal", "Mystic", "On-chain", "Unzipped", "Beta", "Bored", "Bizarre", "Funny", "Uncanny", "Future", "Diffused", "Dat Boi", "Up only", "Tiny", "Perfect", "One way", "Buzzing", "Another"];
    string[100] internal namesListB = ["Tolstoy", "Vincent", "Normie", "Gaga", "Jedi", "Pony", "Snail", "Mustang", "Pokemon", "Tesla", "Russian", "Token", "Obi-Wan", "Bunny", "Baraka", "Bradbury", "Floppy", "Ser", "OG", "Vsrat", "Britney", "Hunter", "Pepe", "Martian", "Elephant", "Vampire", "OpenSea", "Rainbow", "Elon", "NFTits", "Vitalik", "Mad Max", "Gangsta", "Hogwarts", "Candy", "Zckrbrg", "Brin", "Cowboy", "Kanye", "Pornstar", "Mint", "P2P", "Marksist", "Nakamoto", "Panda", "Jelly", "Valhalla", "Tinder", "Alibaba", "Rihanna", "Python", "Cool Cat", "Tokyo", "WAGMI", "Trader", "PFP", "Simpson", "Fren", "Axolotl", "Norton", "Giraffe", "Monkey", "Punk", "Kubrick", "Pop Diva", "Minx", "Badger", "Gonzo", "Sub-Zero", "Java", "Belgian", "Coconut", "Berserk", "Jango", "Hipster", "Unicorn", "Lover", "Parrot", "Squad", "Higgs", "Yacht", "Orwell", "Dwarf", "Samurai", "Lady", "Newton", "Einstein", "Meebit", "Dothraki", "Lipstick", "Liu Kang", "Beyonce", "Ninja", "Kafka", "Han Solo", "Bunya", "Kung Lao", "Dracula", "Lostpoet", "Dikasso"];
    string[100] internal namesListC = ["Riddle", "HODL", "Zen", "Halo", "SZN", "Kudos", "Hooch", "Totalus", "Airlock", "DDoS", "Frenzy", "Heaven", "Eclipse", "Breeze", "Magneto", "Big Bang", "La-la-la", "Bazinga", "Sobriety", "Genesis", "Cringe", "Gas war", "Mantra", "Bosone", "Flash", "Script", "Deploy", "Oops!", "Cobe", "Cosplay", "Elixir", "404", "Tanatos", "Flipside", "Abbatar", "Oddity", "DAO", "Radio", "Firewall", "Log out", "Rapture", "Prana", "Eros", "Output", "Gangbang", "Roadmap", "Ego trip", "Fidenza", "Flow", "Kaizen", "Dope", "Moonwalk", "QQ", "Kung fu", "Lava", "Chiller", "To Go", "Giveaway", "Stream", "Gap", "JPG", "Boost", "Pop up", "LFG", "Magic", "Karma", "Paradox", "Nirvana", "Wallhack", "Delight", "In Law", "Combo", "DYOR", "Inertia", "Yoga", "Big Data", "Excuse", "FOMO", "Spell", "Rush", "Manga", "Bingo", "Input", "Confundo", "Pass", "Cure", "Check in", "Tincture", "Tsunami", "NFT", "Gear", "Loot", "Safari", "High", "Escape", "Posture", "Kickoff", "Karaoke", "Quantum", "Nintendo"];

    // alco base
    string[20] internal alcoBasesList = ["Absinthe", "Akvavit", "Blackcurrant vodka", "Cachaca", "Calvados", "Cognac", "Gin", "Grappa", "Heavily peated scotch", "Horilka", "Mamajuana", "Mezcal", "Moonshine", "Ouzo", "Pastis", "Rum", "Snake wine", "Tequila", "Vodka", "Whisky"];

    // bitter sweets
    string[17] internal bitterSweetsList = ["Almond liqueur", "Anise liqueur", "Apricot liqueur", "Bitter aperitif", "Coffee liqueur", "Fernet", "Fortified wine", "Herbal liqueur", "Jerez", "Orange liqueur", "Passion fruit liqueur", "Raspberry liqueur", "Sake", "Sloe gin", "Strawberry liqueur", "Sugar syrup", "Vermouth"];

    // sour parts
    string[17] internal sourPartsList = ["Aloe vera juice", "Birch sap", "Blood orange juice", "Carambola juice", "Cranberry juice", "Cucumber juice", "Gooseberry juice", "Grapefruit juice", "Guava juice", "Kumquat juice", "Lemon juice", "Lime juice", "Plum juice", "Pulque", "Sour cherry juice", "Tangerine juice", "Yuzu juice"];

    // fruits and herbs
    string[15] internal fruitsAndHerbs = ["Basil leaves", "Black currant", "Cardamom seeds", "Cranberry", "Eucalyptus leaves", "Grapefruit", "Jalapenos", "Lavender sprig", "Lemongrass", "Mint leaves", "Raspberry", "Rosemary sprig", "Sage leaves", "Tarragon leaves", "Watermelon"];

    // dressings
    string[18] internal dressingsList = ["Bitters", "Black pepper", "Cinnamon", "Cloves", "Cocoa powder", "Coconut flakes", "Curry powder", "Curry powder", "Green tea", "Grenadine", "Lapsang souchong tea", "Milky oolong tea", "Orange bitters", "Rare bitters", "Red wine", "Tabasco", "Vanilla", "Worcestershire sauce"];
    uint256[] internal dressingsPinchPostfix;

    // methods
    string[4] internal methodsList = ["Build", "Make it your own way", "Shake", "Stir"];

    // glasses
    string[16] internal glassesList = ["Beer", "Coffee to go", "Goblet", "Highball", "Hurricane", "Iced tea", "Ikea", "Margarita", "Martini", "Old fashioned", "Red wine", "Tea", "Thermo", "Tiki", "Tumbler", "White wine"];
    uint256[] internal glassesCupsList;
    uint256[] internal glassesMugsList;
    uint256[] internal glassesIceCubesList;
    uint256[] internal glassesCrushedIceList;
    uint256[] internal glassesBlocksTopUps;

    // top ups
    string[17] internal topUpsList = ["Any soda", "Any sparkling", "Cava", "Champagne", "Cider", "Cola", "Cremant", "Energy drink", "Franciacorta", "Ginger beer", "Kvass", "Montrachet", "Prosecco", "Root beer", "Seltzer water", "Tonic", "Vintage bubbles"];

    constructor() {
        // dressings
        dressingsPinchPostfix = [1, 2, 3, 4, 5, 16];

        // glasses
        glassesCupsList = [1, 11];
        glassesMugsList = [0, 12];
        glassesIceCubesList = [0, 1, 3, 5, 9, 10];
        glassesCrushedIceList = [2, 4, 6, 11, 12, 13, 14, 15];
        glassesBlocksTopUps = [7, 8, 9];
    }

    function genDrink(uint256 _tokenId) internal view returns (MetaDrinksTypes.Drink memory) {
        uint256 alcoBasePartsCount = genAlcoBasePart(_tokenId);
        uint256 fruitOrHerbRandomness = MetaDrinksUtils.reRollRandomness(_tokenId, "fh");
        uint256 dressingIndex = MetaDrinksUtils.reRollRandomness(_tokenId, "dr") % dressingsList.length;
        uint256 glassIndex = MetaDrinksUtils.reRollRandomness(_tokenId, "gl") % glassesList.length;
        string memory glassPostfix = genGlassPostfix(glassIndex);
        string[] memory names = genNames(_tokenId);
        return MetaDrinksTypes.Drink(
            genSymbol(alcoBasePartsCount),
            names[0],
            names[1],
            names[2],
            alcoBasesList[MetaDrinksUtils.reRollRandomness(_tokenId, "ab") % alcoBasesList.length],
            string(abi.encodePacked(MetaDrinksUtils.uint2str(alcoBasePartsCount), alcoBasePartsCount == 1 ? " part" : " parts")),
            bitterSweetsList[MetaDrinksUtils.reRollRandomness(_tokenId, "bs") % bitterSweetsList.length],
            sourPartsList[MetaDrinksUtils.reRollRandomness(_tokenId, "sp") % sourPartsList.length],
            fruitOrHerbRandomness % 100 < 75,
            fruitsAndHerbs[fruitOrHerbRandomness % fruitsAndHerbs.length],
            dressingsList[dressingIndex],
            MetaDrinksUtils.isUintArrayContains(dressingsPinchPostfix, dressingIndex) ? "pinch" : "dash",
            methodsList[MetaDrinksUtils.reRollRandomness(_tokenId, "me") % methodsList.length],
            genGlass(glassIndex),
            bytes(glassPostfix).length != 0,
            glassPostfix,
            !MetaDrinksUtils.isUintArrayContains(glassesBlocksTopUps, glassIndex),
            topUpsList[MetaDrinksUtils.reRollRandomness(_tokenId, "tu") % topUpsList.length]
        );
    }

    function genNames(uint256 _tokenId) internal view returns (string[] memory result) {
        uint256 randIndex = MetaDrinksUtils.reRollRandomness(_tokenId, "n") % 100;
        uint256 slowIndex = 100 - 1 - (_tokenId + uint256(_tokenId / 100)) % 100;
        uint256 fastIndex = _tokenId % 100;
        result = new string[](3);
        result[0] = namesListA[randIndex];
        result[1] = namesListB[slowIndex];
        result[2] = namesListC[fastIndex];
    }

    function genAlcoBasePart(uint256 _tokenId) internal pure returns (uint256) {
        uint256 prob = MetaDrinksUtils.reRollRandomness(_tokenId, "abp") % 10;
        // 10%
        if (prob == 0) return 0;
        // 20%
        if (prob < 3) return 1;
        // 40%
        if (prob < 7) return 2;
        // 30%
        return 3;
    }

    function genGlass(uint256 _glassIndex) internal view returns (string memory) {
        string memory glass = glassesList[_glassIndex];
        string memory glassTypePostfix;
        if (MetaDrinksUtils.isUintArrayContains(glassesCupsList, _glassIndex)) {
            glassTypePostfix = "cup";
        }
        if (MetaDrinksUtils.isUintArrayContains(glassesMugsList, _glassIndex)) {
            glassTypePostfix = "mug";
        } else {
            glassTypePostfix = "glass";
        }
        return string(abi.encodePacked(glass, " ", glassTypePostfix));
    }

    function genGlassPostfix(uint256 _glassIndex) internal view returns (string memory) {
        if (MetaDrinksUtils.isUintArrayContains(glassesIceCubesList, _glassIndex)) {
            return "ice cubes";
        }
        if (MetaDrinksUtils.isUintArrayContains(glassesCrushedIceList, _glassIndex)) {
            return "crushed ice";
        }
        return "";
    }

    function genSymbol(uint256 _partsCount) internal pure returns (string memory) {
        if (_partsCount == 0) return "\xc2\xa7";
        if (_partsCount == 1) return "$";
        if (_partsCount == 2) return "@";
        return "&amp;";
    }
}
