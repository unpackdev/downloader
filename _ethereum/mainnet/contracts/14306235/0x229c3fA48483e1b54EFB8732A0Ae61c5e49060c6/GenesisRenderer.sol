// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Base64.sol";
import "./Ownable.sol";

interface IGenesisAdventurer {
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getWaist(uint256 tokenId) external view returns (string memory);
    function getFoot(uint256 tokenId) external view returns (string memory);
    function getHand(uint256 tokenId) external view returns (string memory);
    function getNeck(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
    function getOrder(uint256 tokenId) external view returns (string memory);
    function getOrderColor(uint256 tokenId) external view returns (string memory);
    function getOrderCount(uint256 tokenId) external view returns (string memory);
    function getLootTokenIds(uint256 tokenId) external pure returns(uint256[8] memory);
    function getName(uint256 tokenId) external view returns (string memory);
}

interface ILootStats {
    enum Class
    {
        Warrior,
        Hunter,
        Mage,
        Any
    }
    function getLevel(uint256[8] memory tokenId) external view returns (uint256);
    function getGreatness(uint256[8] memory tokenId) external view returns (uint256);
    function getRating(uint256[8] memory tokenId) external view returns (uint256);
    function getNumberOfItemsInClass(Class classType, uint256[8] memory tokenId) external view returns (uint256);
}

contract GenesisRenderer is Ownable {
    address public genesisAdventurerAddress;
    address public lootStatsAddress;
    address public genesisNamingAddress;
    IGenesisAdventurer private ga;
    ILootStats private stats;

    constructor(address genesisAdventurer_, address lootStats_) {
        setGenesisAdventurer(genesisAdventurer_);
        setLootStats(lootStats_);
    }

    function setGenesisAdventurer(address addr_) public onlyOwner {
        genesisAdventurerAddress = addr_;
        ga = IGenesisAdventurer(addr_);
    }

    function setLootStats(address addr_) public onlyOwner {
        lootStatsAddress = addr_;
        stats = ILootStats(lootStatsAddress);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {

      string[27] memory parts;
      string memory name = ga.getName(tokenId);
      uint256[8] memory lootTokenIds = ga.getLootTokenIds(tokenId);
      
      parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; widht: 350px} .italic {font-style: italic} .dark { fill: #000; fill-opacity: .5}</style><rect width="100%" height="100%" fill="#000"/><rect y="300" width="350" height="50" fill="';
      parts[1] = ga.getOrderColor(tokenId);
      parts[2] = '"/><text x="10" y="20" class="base">';
      parts[3] = ga.getWeapon(tokenId);
      parts[4] = '</text><text x="10" y="40" class="base">';
      parts[5] = ga.getChest(tokenId);
      parts[6] = '</text><text x="10" y="60" class="base">';
      parts[7] = ga.getHead(tokenId);
      parts[8] = '</text><text x="10" y="80" class="base">';
      parts[9] = ga.getWaist(tokenId);
      parts[10] = '</text><text x="10" y="100" class="base">';
      parts[11] = ga.getFoot(tokenId);
      parts[12] = '</text><text x="10" y="120" class="base">';
      parts[13] = ga.getHand(tokenId);
      parts[14] = '</text><text x="10" y="140" class="base">';
      parts[15] = ga.getNeck(tokenId);
      parts[16] = '</text><text x="10" y="160" class="base">';
      parts[17] = ga.getRing(tokenId);
      parts[18] = '</text><text x="10" y="320" class="base italic">';
      parts[19] = name;
      parts[20] = '</text><text x="340" y="340" class="base dark" text-anchor="end">';
      parts[21] = ga.getOrder(tokenId);
      parts[22] = ' ';
      parts[23] = ga.getOrderCount(tokenId);
      parts[24] = '</text><text x="10" y="340" class="base dark">Rating ';
      parts[25] = _toString(stats.getRating(lootTokenIds));
      parts[26] = ' / 720</text></svg>';

      string memory image = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
      image = string(abi.encodePacked(image, parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
      image = string(abi.encodePacked(image, parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
      image = string(abi.encodePacked(image, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22]));
      image = string(abi.encodePacked(image, parts[23], parts[24], parts[25], parts[26]));
      string memory attributes = string(abi.encodePacked('{"trait_type": "Order", "value": "', ga.getOrder(tokenId),'"},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Greatness", "value": ', _toString(stats.getGreatness(lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Level", "value": ', _toString(stats.getLevel(lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Rating", "value": ', _toString(stats.getRating(lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Number of Warrior Items", "value": ', _toString(stats.getNumberOfItemsInClass(ILootStats.Class.Warrior, lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Number of Hunter Items", "value": ', _toString(stats.getNumberOfItemsInClass(ILootStats.Class.Hunter, lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Number of Mage Items", "value": ', _toString(stats.getNumberOfItemsInClass(ILootStats.Class.Mage, lootTokenIds)),'},'));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Generation", "value": "Genesis"}'));
      string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "This item is a Genesis Adventurer used in Loot (for Adventurers)", '));
      json = string(abi.encodePacked(json, '"attributes": [', attributes,'], '));
      json = string(abi.encodePacked(json, '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}'));
      json = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
      return json;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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
}