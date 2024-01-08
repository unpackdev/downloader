// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Companion is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public price = 30000000000000000; //0.03 ETH

    //Loot Contract
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface public lootContract = LootInterface(lootAddress);

    string[] private animals = [
        "Dog",
        "Cat",
        "Dragon",
        "Penguin",
        "Goat",
        "Capybara",
        "Bear",
        "Owl",
        "Bunny",
        "Panda",
        "Dino",
        "Monkey",
        "Pig",
        "Fox",
        "Turtle"
    ];
    
    string[] private origin = [
        "Domestic Origin",
        "Forest Origin",
        "Mountains Origin",
        "Sea Origin",
        "Jungle Origin",
        "Sky Origin",
        "Glacier Origin"
    ];
    
    string[] private color = [
        "Black",
        "White",
        "Orange",
        "Purple",
        "Red",
        "Green",
        "Silver",
        "Fire",
        "Ice",
        "Gold",
        "Rainbow"
    ];
    
    string[] private looks = [
        "Scales",
        "Fur",
        "Spots",
        "Stripes"
    ];

    string[] private strength = [
        "Strength 1",
        "Strength 2",
        "Strength 3",
        "Strength 4",
        "Strength 5",
        "Strength 6",
        "Strength 7",
        "Strength 8",
        "Strength 9",
        "Strength 10"
    ];

    string[] private dexterity = [
        "Dexterity 1",
        "Dexterity 2",
        "Dexterity 3",
        "Dexterity 4",
        "Dexterity 5",
        "Dexterity 6",
        "Dexterity 7",
        "Dexterity 8",
        "Dexterity 9",
        "Dexterity 10"
    ];

    string[] private intelligence = [
        "Intelligence 1",
        "Intelligence 2",
        "Intelligence 3",
        "Intelligence 4",
        "Intelligence 5",
        "Intelligence 6",
        "Intelligence 7",
        "Intelligence 8",
        "Intelligence 9",
        "Intelligence 10"
    ];

    string[] private loyalty = [
        "Loyalty 1",
        "Loyalty 2",
        "Loyalty 3",
        "Loyalty 4",
        "Loyalty 5",
        "Loyalty 6",
        "Loyalty 7",
        "Loyalty 8",
        "Loyalty 9",
        "Loyalty 10"
    ];
    
    string[] private suffixes = [
        "the Widow Maker",
        "the Child Eater",
        "the Forgotten One",
        "the Beast Rider",
        "the Dragon Slayer",
        "the Giant Slayer",
        "the Demon Hunter",
        "the Great Protector",
        "the Guardian of the Weak",
        "the Holy Virgin",
        "the Savior of the Lost",
        "the Omen of Destruction",
        "the Keeper of the Light",
        "the Searched Criminal",
        "the Explorer of the Void",
        "the Son of the Arch Angel",
        "the Prophet of Enlightment",
        "the Killer of Angels",
        "the Bringer of Darkness",
        "the Bringer of Doom",
        "the Lord of Wrath",
        "the Keeper of Peace"
    ];
    
    function getAnimal(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ANIMAL", animals);
    }
    
    function getOrigin(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ORIGIN", origin);
    }
    
    function getColor(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "COLOR", color);
    }
    
    function getLooks(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LOOKS", looks);
    }

    function getStrength(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "STR", strength);
    }

    function getDexterity(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "DEX", dexterity);
    }

    function getIntelligence(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INT", intelligence);
    }

    function getLoyalty(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LOYAL", loyalty);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(string(abi.encodePacked(keyPrefix, toString(tokenId))))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;

        if (keccak256(abi.encodePacked(keyPrefix)) == keccak256("ANIMAL") && greatness > 14) {
            output = string(abi.encodePacked(output, ", ", suffixes[rand % suffixes.length]));
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory output = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">',
            getAnimal(tokenId),
            '</text><text x="10" y="40" class="base">',
            getOrigin(tokenId),
            '</text><text x="10" y="60" class="base">',
            getColor(tokenId),
            '</text><text x="10" y="80" class="base">',
            getLooks(tokenId),
            '</text><text x="10" y="100" class="base">'));
        output = string(
            abi.encodePacked(
                output,
                getStrength(tokenId),
                '</text><text x="10" y="120" class="base">',
                getDexterity(tokenId),
                '</text><text x="10" y="140" class="base">',
                getIntelligence(tokenId),
                '</text><text x="10" y="160" class="base">',
                getLoyalty(tokenId),
                '</text></svg>'
            )
        );
        output = string(abi.encodePacked('data:application/json;base64,',
            Base64.encode(bytes(string(abi.encodePacked('{"name": "Companion #', toString(tokenId), '", "description": "Companions are randomized generated and stored on chain. Images and other functionality are intentionally omitted for others to interpret. Feel free to use companions in any way you want. Inspired and compatible with Loot (for Adventurers)", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))))
        ));

        return output;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 8000 && tokenId <= 12000, "Token ID invalid");
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
        require((price * tokenIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 8000 && tokenIds[i] < 12000, "Token ID invalid");
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function mintWithLoot(uint256 lootId) public payable nonReentrant {
        require(lootId > 0 && lootId <= 8000, "Token ID invalid");
        require(lootContract.ownerOf(lootId) == msg.sender, "Not the owner of this loot");
        _safeMint(_msgSender(), lootId);
    }

    function multiMintWithLoot(uint256[] memory lootIds) public payable nonReentrant {
        for (uint256 i = 0; i < lootIds.length; i++) {
            require(lootContract.ownerOf(lootIds[i]) == msg.sender, "Not the owner of this loot");
            _safeMint(_msgSender(), lootIds[i]);
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
    
    constructor() ERC721("Companion", "COMP") Ownable() {}
}