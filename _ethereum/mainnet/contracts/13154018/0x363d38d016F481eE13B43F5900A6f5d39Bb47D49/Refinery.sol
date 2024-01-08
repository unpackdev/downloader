// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getWeapon(uint256 tokenId) external view returns (string memory);
    function getChest(uint256 tokenId) external view returns (string memory);
    function getHead(uint256 tokenId) external view returns (string memory);
    function getWaist(uint256 tokenId) external view returns (string memory);
    function getFoot(uint256 tokenId) external view returns (string memory);
    function getHand(uint256 tokenId) external view returns (string memory);
    function getNeck(uint256 tokenId) external view returns (string memory);
    function getRing(uint256 tokenId) external view returns (string memory);
}

contract Refinery is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 constant public maxGenerations = 5;
    uint256[5] public refineAttemptPrices = [
        20000000000000000, // 0.02 ETH
        30000000000000000, // 0.03 ETH
        50000000000000000, // 0.05 ETH
        90000000000000000, // 0.09 ETH
        150000000000000000 // 0.15 ETH
    ];
    string[8] private refinements = [
        "Destroyed ",
        "Rusty ",
        "",
        "Shiny ",
        "Magical ",
        "Mythic ",
        "Legendary ",
        "Omnipotent "
    ];

    //Loot Contract
    address public lootAddress; // 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    address public xlootAddress; // 0x8bf2f876E2dCD2CAe9C3d272f325776c82DA366d;

    // Mappings from tokenId to values
    mapping(uint256 => uint256) public refineAttempts;
    mapping(uint256 => uint256) public originalLoot;
    mapping(uint256 => uint256) public parentLoot;
    mapping(uint256 => uint256) public generation;

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function generateScore(uint256 tokenId, string memory keyPrefix) private view returns (uint256) {
        if (tokenId <= 16000) {
            return 2;
        }
        uint256 parentScore = generateScore(parentLoot[tokenId], keyPrefix);
        if (parentScore == 0) {
            return 0;
        }
        uint256 rand = uint256(keccak256(abi.encodePacked(string(abi.encodePacked(keyPrefix, toString(tokenId))))));
        uint256 greatness = rand % 100;
        if (greatness < 4) {
            return 0;
        } else if (greatness < 25) {
            return parentScore - 1;
        } else if (greatness < 75) {
            return parentScore;
        } else if (greatness < 95) {
            return min(parentScore + 1, 7);
        } else {
            return min(parentScore + 2, 7);
        }
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "WEAPON", getLootContract(tokenId).getWeapon(originalLoot[tokenId]));
    }

    function getChest(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "CHEST", getLootContract(tokenId).getChest(originalLoot[tokenId]));
    }

    function getHead(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "HEAD", getLootContract(tokenId).getHead(originalLoot[tokenId]));
    }

    function getWaist(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "WAIST", getLootContract(tokenId).getWaist(originalLoot[tokenId]));
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "FOOT", getLootContract(tokenId).getFoot(originalLoot[tokenId]));
    }

    function getHand(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "HAND", getLootContract(tokenId).getHand(originalLoot[tokenId]));
    }

    function getNeck(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "NECK", getLootContract(tokenId).getNeck(originalLoot[tokenId]));
    }

    function getRing(uint256 tokenId) public view returns (string memory) {
        return generateText(tokenId, "RING", getLootContract(tokenId).getRing(originalLoot[tokenId]));
    }

    function getLootContract(uint256 tokenId) private view returns (LootInterface) {
        if (tokenId <= 8000 || (originalLoot[tokenId] >= 1 && originalLoot[tokenId] <= 8000)) {
            return LootInterface(lootAddress);
        }
        return LootInterface(xlootAddress);
    }
    
    function generateText(uint256 tokenId, string memory keyPrefix, string memory output) internal view returns (string memory) {
        uint256 score = generateScore(tokenId, keyPrefix);
        return string(abi.encodePacked(refinements[score], output));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory output = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#333333" /><text x="10" y="20" class="base">',
            "Bag #",
            toString(originalLoot[tokenId]),
            ", Gen ",
            toString(generation[tokenId]),
            '</text><text x="10" y="40" class="base">',
            getWeapon(tokenId),
            '</text><text x="10" y="60" class="base">',
            getChest(tokenId),
            '</text><text x="10" y="80" class="base">',
            getHead(tokenId),
            '</text><text x="10" y="100" class="base">',
            getWaist(tokenId),
            '</text><text x="10" y="120" class="base">',
            getFoot(tokenId),
            '</text><text x="10" y="140" class="base">',
            getHand(tokenId),
            '</text><text x="10" y="160" class="base">',
            getNeck(tokenId),
            '</text><text x="10" y="180" class="base">',
            getRing(tokenId),
            '</text></svg>'
        ));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Refined Bag #', toString(tokenId), '", "description": "rLoot is refined randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function refine(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 0, "Token ID invalid");
        uint256 attempts = refineAttempts[tokenId];
        require(attempts < refineAttemptPrices.length, "Refined max times");
        require(
            // Free for first two generation first attempts
            (generation[tokenId] < 2 && attempts == 0) ||
            refineAttemptPrices[refineAttempts[tokenId]] <= msg.value,
            string(abi.encodePacked("Expected ", toString(refineAttemptPrices[refineAttempts[tokenId]]), " WEI"))
        );
        uint256 nextTokenId = totalSupply() + 16001;
        if (tokenId > 0 && tokenId <= 16000) {
            require(getLootContract(tokenId).ownerOf(tokenId) == msg.sender, "Not the owner of this loot");
            originalLoot[nextTokenId] = tokenId;
        } else {
            require(ownerOf(tokenId) == msg.sender, "Not the owner of this loot");
            require(generation[tokenId] < maxGenerations, "The generation is beyond the end of time");
            originalLoot[nextTokenId] = originalLoot[tokenId];
        }
        refineAttempts[tokenId] += 1;
        parentLoot[nextTokenId] = tokenId;
        generation[nextTokenId] = generation[tokenId] + 1;
        _safeMint(_msgSender(), nextTokenId);
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
    
    constructor(address _lootAddress, address _xlootAddress) ERC721("Refined Loot", "rLOOT") Ownable() {
        lootAddress = _lootAddress;
        xlootAddress = _xlootAddress;
    }
}