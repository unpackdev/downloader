// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**

██████╗░░█████╗░░█████╗░████████╗░░░░░██╗░█████╗░░█████╗░██╗░░██╗
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝░░░░░██║██╔══██╗██╔══██╗██║░██╔╝
██████╦╝██║░░██║██║░░██║░░░██║░░░░░░░░██║███████║██║░░╚═╝█████═╝░
██╔══██╗██║░░██║██║░░██║░░░██║░░░██╗░░██║██╔══██║██║░░██╗██╔═██╗░
██████╦╝╚█████╔╝╚█████╔╝░░░██║░░░╚█████╔╝██║░░██║╚█████╔╝██║░╚██╗
╚═════╝░░╚════╝░░╚════╝░░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝
*/

/// This contract has not been audited. Use at your own risk.

/**
The author generated this text in part with GPT-3, OpenAI’s large-scale language-generation model. 
Upon generating draft language, the author reviewed, edited, and revised the language to their own liking 
and takes ultimate responsibility for the content of this publication.
*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

contract bootjack0 is ERC721, ReentrancyGuard, Ownable {
    struct MintInfo {
        uint256 cost;
        uint32 maxSupply;
        uint32 nextTokenId;
    }
    MintInfo mintInfo = MintInfo(0.01 ether, 5000, 1);


    string[] private weapons = [
        "Blaster Pistol",
        "Chainsaw",
        "Deadly Dust",
        "Stone Burner",
        "Shard Dagger",
        "Concussion Bomb",
        "Wide-bore Burner",
        "Cellgun",
        "Small Club",
        "Battle Lance",
        "Vara Lance",
        "Cobra",
        "Wingman",
        "Shock Trooper Rifle",
        "Lasrifle",
        "Jericho 941",
        "Pulse Cannon",
        "Glock 30",
        "Slagger",
        "Walther P99",
        "Heckler Koch MP5A2",
        "Quill Gun",
        "Zorg ZF-1",
        "Sonic Club",
        "Directed Energy Cannon",
        "Barbed Spear",
        "Mangalore CP1",
        "Mangalore AK",
        "M2HB",
        "Mauser M712",
        "Electrical Spear",
        "Lewis Gun",
        "Short Spear",
        "Maula Pistol",
        "MAC-10",
        "Laser Rifle",
        "Pipe",
        "Hatchet",
        "Key Sword",
        "Bad Lancer",
        "Energy Whip",
        "Battle Hammer",
        "Battle Axe",
        "Laser Sword",
        "Battlehammer",
        "Scythe",
        "Halberd Sword",
        "Power Pole",
        "Colt Commando",
        "Flamethrower",
        "Cane Gun",
        "M197 Vulcan",
        "Lightning Rifle",
        "Desert Eagle",
        "Dart Gun",
        "Switch Blade",
        "SW 19",
        "Katana",
        "Plasma Cannon",
        "Squid Gun",
        "2x4",
        "Baseball Bat",
        "Disruptor",
        "Micro Uzi",
        "Automatic Shotguns x2",
        "M16",
        "Phaser",
        "92FS",
        "Tarpel Gun",
        "Fusion Rifle",
        "AMC Auto Mag",
        "Submachine Gun",
        "P226",
        "Combat Bow",
        "Shotgun",
        "Trace Rifle",
        "Pulse Rifle",
        "Machete",
        "Hand Cannon",
        "Derringer",
        "Scout Rifle",
        "Machine Gun",
        "Power Sword",
        "Trident",
        "Grenade Launcher",
        "Sniper Rifle",
        "Blitmap",
        "Two Twenty",
        "Pump Shotgun",
        "Longbow",
        "Frag Grenade",
        "PC-9",
        "Stinger",
        "PS20",
        "Scorpio",
        "M79",
        "Vulcan Minigun",
        "Killer7",
        "Pipe Gun",
        "Stun Baton",
        "Nailgun",
        "Rocket Launcher",
        "Laser Cannon",
        "Crowbar",
        "Molotov Cocktail",
        "Doritos Bag and Zipties"
    ];

    string[] private clothing = [
        "White Tshirt",
        "Hack The Planet TShirt",
        "Bomber Jacket",
        "Armor-Quilted Jacket",
        "Yukata",
        "Ballistic Vest",
        "Polycarbonate Turtleneck",
        "Hybrid Weave Sweater",
        "Thermoset Jacket",
        "Graphene-Weave Jacket",
        "Silk Kimono",
        "Levitation Boots",
        "Gladiator Armor",
        "Dri-Fit Shirt",
        "Anti-Puncture Shirt",
        "Interface Suit",
        "Hordak Bone Armor",
        "Doritos Hoodie",
        "Thermoactive Jacket",
        "Synweave Dress",
        "Duolayer Puffer Vest",
        "Samurai Turtleneck",
        "Surge Jogger",
        "Synweave Yukata",
        "Survival Suit",
        "Synweave Jacket",
        "Gold Silk Vest",
        "Nikon Cloak",
        "Flex Stride Shorts",
        "Isolation Suit",
        "Metal Vent T-shirt",
        "EV Suit",
        "Bio-mimetic Garment",
        "Flight Suit",
        "Neon Orange Puffer Vest",
        "Polycarb Trench Coat",
        "Leather Trench Coat",
        "Fur Coat",
        "White Wool Turtleneck",
        "Tactical Coat",
        "Transparent Trench",
        "Black Leather Overcoat",
        "RunDao Tshirt",
        "Devotion Robes",
        "Leopard Parachute Pants",
        "Leather Moto Jacket",
        "Cat Rose TShirt",
        "Suzuki Moto Jacket",
        "Tactical Vest",
        "Knight Robes",
        "Power Suit",
        "Doritos Polo",
        "Blitmap Tshirt",
        "Patagonia Vest",
        "Hover Suit",
        "Planeswalker Cloak",
        "Terry Cloth Bathrobe",
        "Kevlar Vest",
        "Duct Tape Overcoat",
        "Tie Dye Overalls",
        "Wet Suit",
        "Power Armor",
        "Planeswalker Armor",
        "Ion Suit",
        "Suit of Power",
        "Leather Jacket",
        "Leather Overcoat",
        "Silk Dress",
        "Ice Princess Robes",
        "Plaid Shirt",
        "Morning Coat",
        "Vestments of Faith",
        "Red Hoodie",
        "Squid Suit",
        "Lizard Scale Mail",
        "Dragon Skin Cloak",
        "Denim Overalls",
        "Longcoat",
        "Leather Armor",
        "Military Fatigues",
        "Bunny Suit",
        "Fallen Angel Robes",
        "Black Leather Armor",
        "Fur Lined Cloak",
        "Sorceress Robes",
        "Pleather Pants",
        "Tribal Skirt",
        "Pleather Armor",
        "Leather Vest",
        "Leather Pants",
        "Avant Garde Dress",
        "Ranger's Tunic",
        "Bunny Suit",
        "Knight Armor",
        "Duelist Plate"
    ];

    string[] private vehicle = [
        "Cybertruck",
        "Ornithopter",
        "VTOL",
        "Groundcar",
        "Moto Guzzi 850",
        "ForFour",
        "Combat Tank",
        "Suburban",
        "Civilian",
        "F Series Pickup",
        "Alfa Romeo Spinner",
        "GM TDH 4507",
        "Armadillo Van",
        "Dust Scout",
        "Raider Trike",
        "Audi A4",
        "SAAB 99",
        "KLR 650 Bike",
        "Audi TT",
        "Globefish",
        "Hovercar",
        "Jupiter 8",
        "Jet Squirrel",
        "Cadilac Eldorado",
        "1969 Ford Mustang",
        "Ducati Scrambler 1100",
        "Porsche 912",
        "Ford Granada",
        "Sonic Tank",
        "MB Unimog",
        "Spice Rocket",
        "BMW 2002",
        "Crown Victoria",
        "Cube",
        "Armored Limousine",
        "Sand Crawler",
        "Ford Raptor",
        "MV Agusta F4",
        "Lamborghini Countach",
        "Ferrari F40",
        "Porsche 911 Carrera RS",
        "Volkswagen Beetle",
        "Peugot Spinner",
        "Squidder",
        "Cannondale Roadbike",
        "Scout Flyer",
        "Levtrain",
        "Steel Quads",
        "Spinner",
        "Blitmap Bus",
        "Doritos Delivery Truck",
        "Forklift",
        "RV",
        "Formula Racer",
        "Rally Fighter",
        "Roadster",
        "Blimp",
        "Custom Hot Rod",
        "Big Rig",
        "Aerodyne",
        "Electrola Roadster",
        "Tesla Model 3"
    ];

    string[] private gear = [
        "Tactical Belt",
        "Carbon Fiber Belt",
        "Bandolier of Ammo",
        "Katana Sheath",
        "EpiPen",
        "Mega Today Magazine",
        "Orange Sweatband",
        "Code Bomb",
        "Yellow Sweatband",
        "Green Sweatband",
        "Indigo Sweatband",
        "White Sweatband",
        "Black Sweatband",
        "Destron Gas",
        "Tez Bot Software",
        "Bugout Bag",
        "Case of Jolt Cola",
        "Hard Hat",
        "Lockpicking Kit",
        "Skull Fest Ticket",
        "Gibson Garbage File",
        "Neo Christianist Pamphlets",
        "Havoc Goggles",
        "Bandages",
        "Medical Kit",
        "Hackers Utility Belt",
        "Marauders Bag",
        "Arena Bet Ticket",
        "GM Book of Secrets",
        "Pistol Holster",
        "Rusty Nails",
        "Squid Camo Net",
        "MC Royals Ticket",
        "Running Socks",
        "Traag Knowledge Book",
        "Funnel Web Spider Poison",
        "Crate of Bottled Water",
        "Club 21 VIP Pass",
        "Duct Tape",
        "Archery Quiver",
        "Pink Shirt Book",
        "Red Book",
        "Devil Book",
        "Dragon Book",
        "Polycarb Belt",
        "Safety Glasses",
        "Doritos Clipboard",
        "Advanced Robotics",
        "Yamada Robotics Belt",
        "Black Nail Polish",
        "Runner's Belt",
        "Broken Scissors",
        "Water Bottle Belt",
        "Wire Cutters",
        "Flare Gun",
        "Alien Tech Belt",
        "Bot Wiring",
        "Doritos Windbreaker",
        "Hackers Backpack",
        "Leather Fanny Pack",
        "Hacker Belt",
        "Blitmaps Tote",
        "Patagonia Tech Web"
    ];

    string[] private footwear = [
        "Pegasus",
        "Floatride",
        "UltraBoost",
        "Ghost",
        "Endorphin Pro",
        "Wave Rebellion",
        "ZWorth Air",
        "Air Max 94",
        "Deviate Nitro",
        "One Carbon",
        "Avatar Boot",
        "Meta Speed",
        "Rincon 3",
        "Adipure",
        "Five Fingers",
        "Fuel Cell",
        "Inline Skates",
        "Triumph",
        "Speedcross",
        "Wave Elixir",
        "Air Rift",
        "Ultraride",
        "Ultra Kiawe",
        "Charge",
        "Sprint",
        "Pulse",
        "Cadence",
        "Rocket Boots",
        "Skateboard Shoes",
        "Bionic Boots",
        "Cortana 2",
        "Plasma Boots",
        "Momentum",
        "Max 97",
        "Ghost Racer",
        "MZ-84",
        "Heman Boots",
        "Free Runner",
        "Skytop II",
        "Marathon",
        "Max 180",
        "Cloud Runner",
        "Leather Boots",
        "Pure Cadence",
        "GL6000",
        "Presto",
        "Crosstown",
        "TX-3",
        "Cephpod Runner",
        "Tactical Boots",
        "Zoom JST",
        "Street Glide",
        "Super Man",
        "Cybershoes",
        "Skytop II",
        "Cruzer",
        "Proto Boot",
        "Air Force 1",
        "Wave Rider",
        "Max 95",
        "Citizen",
        "Waffle Trainer",
        "El Tigre",
        "ZX 500",
        "Hover Boots",
        "Power Boots",
        "Boost Boots",
        "Huarache",
        "Gravity",
        "Bermuda",
        "Bot Boots",
        "Slides",
        "Furlined Tactical Boots",
        "Mil Spec Boot",
        "Alien Tek Runer",
        "Skull Sneaker",
        "SL 72",
        "Cortez",
        "Air Flow",
        "Easy Rider",
        "Allbirds",
        "Velcro Runners",
        "Custom Doritos Hightops",
        "Blitmap Boots"
    ];

    string[] private hardware = [
        "Tablet",
        "Code Book",
        "Worm Program USB",
        "EM Pulse Generator",
        "Laptop",
        "Raspberry Pi 3",
        "Neural Link",
        "Reality Machine",
        "Coat Check Keycard",
        "Bag of Marbles",
        "ST88 X",
        "Laser Tripwire",
        "Miniature EMP Generator",
        "Retinal Scanner",
        "Hallusomnetic Chair",
        "USBArmory",
        "LinkCore Prototype",
        "OutKast CD",
        "Zotax GTX 1050 Ti Mini",
        "Wireless Headphones",
        "Mechanical Keyboard",
        "Bash Bunny",
        "Wrench",
        "Ubertooth 1",
        "Wifi Pineapple",
        "Zigbee",
        "Gaming Computer",
        "Rubber Ducky",
        "Voice Changer",
        "Long-Range Antenna",
        "KeyLogger",
        "Da Vinci Virus Drive",
        "GPS Tracking Device",
        "Proxmark 3",
        "Fitbit",
        "Blackberry",
        "Nokia Brick",
        "Motorola Razr",
        "Mind Control Device",
        "Satelite Orbital Laser",
        "Cryogenic Containment Unit",
        "Hardware Wallet",
        "ROM Module",
        "EMP Shield",
        "Mini Drone",
        "RFID Duplicator",
        "Blitmap Decoder",
        "Smartphone",
        "Doritos HQ Key Card"
    ];

    string[] private loot = [
        "Gold Coins",
        "Silver Coins",
        "Synthetic Diamonds",
        "Platinum Bars",
        "Titanium Orbs",
        "Opalfire Jewels",
        "Fire Jewels",
        "Stolen Credits",
        "Tanzanite Stones",
        "Taffeite Stones",
        "Processing Chips",
        "Black Opals",
        "Benitoite Stones",
        "Musgravite Stones",
        "$RunFree Tokens",
        "Painite Stones",
        "Hagal Stones",
        "Star Jewels",
        "Royals Championship Ring",
        "Painite Stones",
        "Infinity Stones",
        "Bot Chips",
        "Tek Fuel",
        "Skull Key",
        "Race Medals",
        "Cool Ranch Doritos",
        "Special Candy",
        "Rich Stones",
        "Musgravite Gemstones"
    ];

    string[] private locations = [
        "Sector 1",
        "Sector 2",
        "Sector 3",
        "Sector 4",
        "Sector 5",
        "Sector 6",
        "Sector 7",
        "Sector 8",
        "Sector 9",
        "Sector 10",
        "Sector 11",
        "Sector 12",
        "Alpha District",
        "Beta District",
        "Gamma District",
        "Delta District",
        "Zeta District"
    ];

    string[] private destinations = [
        "Arts District",
        "Dark Woods",
        "Lost Sector",
        "Cabled Underground",
        "Crispr Lab",
        "Mega City Slums",
        "The Lotus Temple",
        "Wreckers Row",
        "Nightlife District",
        "The Outskirts",
        "The Squid Palace",
        "The Hub",
        "The Walls",
        "Etown",
        "The Cliffs",
        "Mega City Cafe",
        "The Somnetic Pagoda",
        "The Lucky Club",
        "Alien Ninja Clan HQ",
        "Nekogumi HQ",
        "The Neo-Bellagio",
        "The Tech District",
        "Blue Side",
        "Interstellar Port",
        "The Flying Snark",
        "Betty Jean's Titty Bar",
        "Red Eye Syndicate Layer",
        "Sand Volley Ball Arena",
        "Mega City Radio Station",
        "Skull District",
        "The Ice Cream Factory",
        "Buseo Boxing Gym",
        "Club 21",
        "The Tracks",
        "The Bitpacking District",
        "ZK Uptown",
        "MC Ghetto",
        "Quad Stream River District",
        "Chain Alleys",
        "Yamada Robotics HQ",
        "Blitcorp HQ",
        "Alien Station Z",
        "Mummy Cult House",
        "Millennium Archives",
        "Mega Mobile HQ",
        "Cascadia Marketplace",
        "Tezark Industries HQ",
        "Dorito Gang District",
        "Mega City Hospital",
        "Skull Base 0",
        "The Sewers",
        "Downtown",
        "The Neo Christianist Temple",
        "The Surgeon's Lab",
        "Armory  Annex",
        "Megaplex Grid",
        "Ybur",
        "Doritos Mega City HQ",
        "Bot Town",
        "Hal's Hardware",
        "Cool Ranch Club",
        "Ed's Laundry Emporium",
        "Temple of Gold",
        "Hansen Hills",
        "The Lighthouse",
        "Mega City Super Max",
        "Mega City Clink"
    ];

    string[] private contraband = [
        "Awareness Spectrum",
        "Elacca ",
        "Rossak",
        "Sapho",
        "Spice Melange",
        "EPO",
        "Stolen Black Cherry Tobacco",
        "HGH",
        "Diuretics",
        "Bootleg Speed",
        "Darkweb Entheogens",
        "Neuroin",
        "Chain Ale",
        "Virgilium",
        "Red Pills",
        "Cyberpharmetics",
        "Runner's Delight",
        "Rachag",
        "Nuke",
        "Blue Pills",
        "Mystery Pills",
        "Bathtub Aspirin",
        "Muscle",
        "Red Eye",
        "Pirated Petrol",
        "Moon",
        "Stardust",
        "Blues",
        "Carbon Powder",
        "Reds",
        "Synaptizine",
        "Tropicaine",
        "Cortexiphan",
        "Pleuromutilin",
        "Cyalodin",
        "Hydronalin",
        "Squid Ink",
        "Felicium",
        "Snakeleaf",
        "Tropolisine",
        "Synthehol",
        "Maraji Crystals",
        "Ephemerol",
        "Substance D",
        "Adrenochrome",
        "DMT-7",
        "4-Diisopropyltryptamine",
        "Soma",
        "Plutonian Nyborg",
        "Vellocet ",
        "Bootleg Whiskey",
        "Doritos Dust",
        "Blits",
        "OPM"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }

    function getClothes(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CLOTHING", clothing);
    }

    function getVehicle(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "VEHICLE", vehicle);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "FOOTWEAR", footwear);
    }

    function getHardware(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HARDWARE", hardware);
    }

    function getGear(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GEAR", gear);
    }

    function getContraband(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "CONTRABAND", contraband);
    }

    function getLoot(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LOOT", loot);
    }

    function getLocation(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LOCATION", locations);
    }

    function getDestinations(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(tokenId, "DESTINATION", destinations);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {

        string memory svg = string(
            abi.encodePacked(
                '<svg width="350" height="350" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">'
                ' <style type="text/css">text { font-size: 16px; font-family: monospace }</style><path fill="#666666" d="M0 0h350v350H0z"/><path fill="#141d26" d="M7.625 18.94h332.857v318.846H7.625z"/><text x="1" y="19" font-size="14" transform="matrix(.57542 0 0 .51254 7.41 5.37)" font-weight="bold">Mega Mobile</text>'
                '<text font-weight="bold" x="340" y="129.5" font-size="10" font-family="Monospace" transform="matrix(.62 0 0 .62682 78.1 264.932)">POWER(((</text><ellipse cx="339" cy="344" rx="3" ry="3"/><text fill="#56aaff" x="66" y="140" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Weapons:</text><text fill="#fff" x="150" y="140" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getWeapon(tokenId),
                '</text><text fill="#56aaff" x="56" y="175" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Clothing:</text><text fill="#fff" x="149" y="175" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getClothes(tokenId),
                '</text><text fill="#56aaff" x="53" y="211" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Vehicles:</text> <text fill="#fff" x="150" y="211" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getVehicle(tokenId),
                '</text><text fill="#56aaff" x="40" y="246" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Contraband:</text><text fill="#fff" x="152" y="246" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getContraband(tokenId),
                '</text><text fill="#56aaff" x="55" y="280" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Footwear:</text><text fill="#fff" x="151" y="280" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getFoot(tokenId),
                '</text><text fill="#56aaff" x="57" y="312" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Hardware:</text><text fill="#fff" x="153" y="312" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getHardware(tokenId),
                '</text><text fill="#56aaff" x="94" y="348" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Gear:</text><text fill="#fff" x="153" y="348" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getGear(tokenId),
                '</text><text fill="#56aaff" x="92" y="383" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Loot:</text><text fill="#fff" x="154" y="383" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getLoot(tokenId),
                '</text><text fill="#56aaff" x="74" y="509" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Depart:</text><text fill="#fff" x="153" y="509" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getLocation(tokenId),
                '</text><text fill="#56aaff" x="73" y="540" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Arrive:</text><text fill="#fff" x="153" y="540" transform="matrix(.63218 0 0 .53353 9.989 18.418)">',
                getDestinations(tokenId),
                '</text><text fill="#00bf00" x="12" y="21" font-size="12" font-family="Monospace" transform="matrix(.63218 0 0 .53353 9.989 18.418)">Loading Transmission...</text><text fill="#00bf00" x="44" y="96" font-size="12" font-family="Monospace" transform="matrix(.63218 0 0 .53353 9.989 18.418)">DECODING...</text><path d="M52.738 13.268h.57l.175-.541.176.54h.569l-.46.335.175.54-.46-.334-.46.334.175-.54-.46-.334zM57.962-20.562h.569l.176-.54.176.54h.569l-.46.334.175.54-.46-.334-.46.335.175-.541-.46-.334z" fill="#4c4c4c"/><path d="M328.996 11.248h1.75v5.75h-1.75zM332.746 8.748h2v8.25h-2zM336.746 6.248h2.25v10.75h-2.25z"/><text fill="#00bf00" x="20" y="424" font-size="12" font-family="Monospace" transform="matrix(.63218 0 0 .53353 9.989 18.418)">/destinations.scan</text><text fill="#00bf00" x="38" y="465" font-size="12" font-family="Monospace" transform="matrix(.63218 0 0 .53353 9.989 18.418)">DECODING...</text><text font-weight="bold" x="15" y="297" font-size="12" font-family="Monospace" transform="matrix(.65037 0 0 .62682 -2.067 159.599)">Somcom a0.1</text><text fill="#00bf00" x="21" y="62" font-size="12" font-family="Monospace" transform="matrix(.63218 0 0 .53353 9.989 18.418)">/manifest.rootkit</text>'
                "</svg>"
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                ' "attributes":[{"trait_type": "weapons", "value":"',
                getWeapon(tokenId),
                '"},{"trait_type": "clothing", "value": "',
                getClothes(tokenId),
                '"},{"trait_type": "vehicle", "value": "',
                getVehicle(tokenId),
                '"},{"trait_type": "contraband", "value": "',
                getContraband(tokenId),
                '"},{"trait_type": "footwear", "value": "',
                getFoot(tokenId),
                '"},'
            )
        );

        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type": "hardware", "value": "',
                getHardware(tokenId),
                '"},{"trait_type": "gear", "value": "',
                getGear(tokenId),
                '"},{"trait_type": "loot", "value": "',
                getLoot(tokenId),
                '"},{"trait_type": "location", "value": "',
                getLocation(tokenId),
                '"},{"trait_type": "destination", "value": "',
                getDestinations(tokenId),
                '"}]'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Manifest #',
                        toString(tokenId),
                        '", "description": "WARNING: Unauthorized network access detected. Destroy this confidential com immediately. Failure to do so is a violation of Mega Mobile Terms of Service.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '",',
                        attributes,
                        "}"
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function claim(uint256 _mintAmount, string calldata key) public payable {
        require(_mintAmount > 0);
        require(_mintAmount <= 10);
        require(mintInfo.nextTokenId + _mintAmount <= mintInfo.maxSupply);

        // Get the hash of the senders address, the runners tokenId, and the key passed
        // This way the key will be different for everyone and they can't just share
        bytes32 sig = keccak256(abi.encodePacked(msg.sender, key));
        uint256 bits = uint256(sig);
        // With a difficulty of 2 we require the last 2 bits to be 0 which gives a 25% hit rate
        uint256 mask = 0x07; // 0x03 is 00000011, aka a byte with the last 2 bits set to true
        require(bits & mask == 0, "INVALID_CODE/ip has been logged");

        if (msg.sender != owner()) {
            require(msg.value >= mintInfo.cost * _mintAmount);
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, mintInfo.nextTokenId);
            mintInfo.nextTokenId++;
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("bootjack", "BOOT") Ownable() {}
}


