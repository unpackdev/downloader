// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Math.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DungeonLoot is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public max_supply = 7777;
    uint256 public mint_price = 50000000000000000;

    string private _contractURI;

    address payable admin;

    ProxyRegistry private _proxyRegistry;
    Counters.Counter private _tokenIds;

    string[] public quality = [
        "Burned",
        "Shining",
        "Superior",
        "Ancient",
        "Smoldering",
        "Rough",
        "Rune-scribed",
        "Oily",
        "Grimy",
        "Carved",
        "Delicate",
        "Glowing",
        "Chipped",
        "Epic",
        "Pristine",
        "Burned",
        "Legendary",
        "Ornate",
        "Fine"
    ];
    string[] public origin = [
        "Abyssal",
        "Astral",
        "Dark Elven",
        "Draconic",
        "Dwarven",
        "Elemental",
        "Elven",
        "Earthen",
        "Ghoulish",
        "Gnomish",
        "Goblinoid",
        "Heavenly",
        "Hellish",
        "Orcish",
        "Undead",
        "Vampiric"
    ];
    string[] public item = [
        "Morningstar",
        "Flail",
        "Spear",
        "Shortsword",
        "Longsword",
        "Great Sword",
        "Rapier",
        "Dagger",
        "Scale Mail",
        "Axe",
        "Battleaxe",
        "Light Crossbow",
        "Crossbow",
        "Heavy Crossbow",
        "Hammer",
        "War Hammer",
        "Rod",
        "Wand",
        "Bow",
        "Long Bow",
        "Chain Mail",
        "Steal Armor",
        "Iron Armor",
        "Studded Leather Armor",
        "Leather Armor",
        "Mask",
        "Glove",
        "Chain Shirt",
        "Tooth",
        "Bone",
        "Tiara",
        "Circlet",
        "Ring",
        "Amulet",
        "Necklace",
        "Stone",
        "Candle",
        "Jewelry Box",
        "Statue",
        "Pipe",
        "Shield",
        "Sphere",
        "Orb",
        "Finger Bone",
        "Plate Mail",
        "Quill",
        "Glaive",
        "Cape",
        "Pauldrons",
        "Lamp",
        "Goblet",
        "Buckle",
        "Crown",
        "Bowl",
        "Spike",
        "Boots",
        "Half-Plate",
        "Arrow",
        "Key",
        "Medallion",
        "Vial",
        "Quarter Staff",
        "Idol",
        "Bird Skull",
        "Pipe",
        "Finger Bone"
    ];
    string[] public power = [
        "Bane",
        "Fear",
        "Blight",
        "Slaying",
        "Stinking Cloud",
        "Scorching Rays",
        "Summoning",
        "Mystical Stepping",
        "Striking",
        "Lightning",
        "Missile Summoning",
        "Haste",
        "Curing",
        "Comprehend Languages",
        "Power",
        "Black tentacles",
        "Cold",
        "Invisibility",
        "Fog",
        "Burning",
        "Acid Arrows",
        "Banishment",
        "Banishment",
        "Blessing",
        "Blight",
        "Blood Feasting",
        "Charming",
        "Cloudkill",
        "Curses",
        "Dimsight",
        "Discernment",
        "Disease",
        "Disintegration",
        "Disintegration",
        "Dust Cloud",
        "Element Absorption",
        "Enfeeblement",
        "Evil",
        "Fear",
        "Fire",
        "Flame",
        "Flying",
        "Forest",
        "Gaseous Form",
        "Haste",
        "Haunting",
        "Impotence",
        "Inferno",
        "Invulnerability",
        "Jumping",
        "Laughing",
        "Light",
        "Magic Detection",
        "Might",
        "Oozing",
        "Plague",
        "Planewalking",
        "Poor Accuracy",
        "Scrying",
        "Shattering",
        "Shattering",
        "Shocking",
        "Silence",
        "Sleep",
        "Slipperiness",
        "Slowing",
        "Smoke Clouds",
        "Speed",
        "Stealth",
        "Stone",
        "Stoneskin",
        "Storms",
        "The Stars",
        "the Wind",
        "The Winds",
        "Thunder",
        "Truesight",
        "Truth",
        "Webs",
        "Wounds"
    ];

    string[] public elemental = ["Fire", "Water", "Earth", "Light", "Dark"];

    string[] public elementalColor = [
        "#EC008C", // Fire
        "#00AEEF", // Water
        "#82CA9C", // Earth
        "#FFF200", // Light
        "#8781BD" // Dark
    ];

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only Owner allowed");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address payable _admin,
        address openseaProxyRegistry_
    ) ERC721(_name, _symbol) {
        admin = _admin;
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }
    }

    function mint(uint256 _amount) public payable nonReentrant {
        require(uint256(mint_price).mul(_amount) == msg.value, "Invalid value");
        require(_amount <= 20, "Cannot mint more than 20 at a time");
        require(
            _tokenIds.current().add(_amount) <= max_supply,
            "Mint exceeds max supply"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 newNftTokenId = _tokenIds.current();
            _safeMint(msg.sender, newNftTokenId);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Adventurer Pack #',
                    _tokenId.toString(),
                    '","image_data":"',
                    img(_tokenId),
                    '"}'
                )
            );
    }

    function img(uint256 _tokenId) internal view returns (string memory) {
        uint256 inventorySize = (determineInt(
            string(abi.encodePacked("INVENTORY", _tokenId.toString()))
        ) % 5) + 1;

        string memory svg;
        svg = concat(svg, "<svg xmlns='http://www.w3.org/2000/svg' width='512px' height='512px' ><rect width='100%' height='100%' fill='");
        svg = concat(svg, elementalColor[
            ((determineInt(
                string(abi.encodePacked("elemental", _tokenId.toString()))
            ) % 5) + 1) % elementalColor.length
        ]);
        svg = concat(svg, "'/>");

        for (uint8 i = 0; i < inventorySize; i++) {

            svg = concat(svg, string(abi.encodePacked("<text x='10' y='",  uint256(((i + 1) * 20)).toString(), "'>")));
            svg = concat(svg, getGear(_tokenId, i));
            svg = concat(svg, '</text>');
            if (i + 1 == inventorySize && inventorySize != 5) {
                uint256 gold = (determineInt(
                    string(abi.encodePacked("GOLD", _tokenId.toString()))
                ) % 100) + 1;
                svg = concat(svg, string(abi.encodePacked("<text x='10' y='", uint256(((i + 2) * 20)).toString(), "'>")));
                svg = concat(svg, string(abi.encodePacked(gold.toString(), " Gold")));
                svg = concat(svg, '</text>');
            }
        }
        svg = concat(svg, '</svg>');
        return svg;
    }

    function determineInt(string memory _in) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_in)));
    }

    function getGear(uint256 _tokenId, uint256 _lIdx)
        public
        view
        returns (string memory)
    {

        // base vars
        string memory tokenStr = _tokenId.toString();
        string memory lIdxStr = _lIdx.toString();
        string memory itemName = "Lvl.";

        // level
        itemName = concat(itemName, ((_lIdx % 10) + 1).toString());
        itemName = concat(itemName, " ");

        // quality
        itemName = concat(itemName, quality[
            determineInt(string(abi.encodePacked("QUALITY", lIdxStr, tokenStr))) % quality.length
        ]);
        itemName = concat(itemName, " ");

        // origin
        itemName = concat(itemName, origin[
            determineInt(string(abi.encodePacked("ORIGIN", lIdxStr, tokenStr))) % origin.length
        ]);
        itemName = concat(itemName, " ");

        // item
        itemName = concat(itemName, item[determineInt(string(abi.encodePacked("ITEM", lIdxStr, tokenStr))) % item.length]);
        itemName = concat(itemName, " of ");

        // power
        itemName = concat(itemName, power[
            determineInt(string(abi.encodePacked("POWER", lIdxStr, tokenStr))) % power.length
        ]);
        itemName = concat(itemName, " ");
        return itemName;
    }

    function concat(string memory _base, string memory _value) internal view returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint256 i;
        uint256 j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    function withdraw(uint256 amount) external payable onlyAdmin {
        require(amount <= address(this).balance);
        admin.transfer(amount);
    }

    function updatePrice(uint256 _gwei) public onlyAdmin {
        mint_price = _gwei;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = _proxyRegistry;
        return
            address(proxyRegistry) != address(0) &&
            address(proxyRegistry.proxies(owner)) == operator;
    }

    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
    }

    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setOpenSeaRegistry(address proxyRegistryAddress)
        external
        onlyAdmin
    {
        _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
