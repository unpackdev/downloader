// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface CyberpunkInterface {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface GearInterface {
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract CharactersForCyberpunks is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // Public mint price for non-holders
    uint256 public constant PUBLIC_MINT_PRICE = 15000000000000000; //0.015 eth

    // Counters
    uint256 public constant TOTAL_MINTS = 10000;
    Counters.Counter private _totalSupplyTracker;

    // Loot (for Cyberpunks) Contract
    // Temporarily overriding this to a different address for testing purposes
    address public cyberpunkAddress = 0x13a48f723f4AD29b6da6e7215Fe53172C027d98f;
    CyberpunkInterface cyberpunkContract = CyberpunkInterface(cyberpunkAddress);

    // Gear (for Punks) Contract
    address public gearAddress = 0xFf796cbbe32B2150A4585a3791CADb213D0F35A3;
    GearInterface gearContract = GearInterface(gearAddress);

    function _totalSupply() internal view returns (uint256) {
        return _totalSupplyTracker.current();
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply();
    }

    string[] private characterTypes = [
        "Rockerboy",
        "Merc",
        "Netrunner",
        "Techie",
        "Media",
        "Cop",
        "Corpo",
        "Fixer",
        "Nomad",
        "Street Samurai",
        "Cultist",
        "Streetkid",
        "AI",
        "Ripperdoc"
    ];

    string[] private originCity = [
        "Chiba City",
        "Night City",
        "Barrytown",
        "Neo Tokyo",
        "Chicago",
        "Hong Kong",
        "Los Angeles",
        "Manchester",
        "New York",
        "Bay City",
        "Mr. Lee's New Hong Kong",
        "Niihama",
        "The Badlands",
        "The Sprawl",
        "Beyond the Blackwall",
        "L Bob Rife's Raft"
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

    string[] private reflexes = [
        "Reflexes 1",
        "Reflexes 2",
        "Reflexes 3",
        "Reflexes 4",
        "Reflexes 5",
        "Reflexes 6",
        "Reflexes 7",
        "Reflexes 8",
        "Reflexes 9",
        "Reflexes 10"
    ];

    string[] private cool = [
        "Cool 1",
        "Cool 2",
        "Cool 3",
        "Cool 4",
        "Cool 5",
        "Cool 6",
        "Cool 7",
        "Cool 8",
        "Cool 9",
        "Cool 10"
    ];

    string[] private tech = [
        "Technical Ability 1",
        "Technical Ability 2",
        "Technical Ability 3",
        "Technical Ability 4",
        "Technical Ability 5",
        "Technical Ability 6",
        "Technical Ability 7",
        "Technical Ability 8",
        "Technical Ability 9",
        "Technical Ability 10"
    ];

    string[] private luck = [
        "Luck 1",
        "Luck 2",
        "Luck 3",
        "Luck 4",
        "Luck 5",
        "Luck 6",
        "Luck 7",
        "Luck 8",
        "Luck 9",
        "Luck 10"
    ];

    string[] private lastName = [
        "Shaw",
        "Tyrell",
        "Sebastian",
        "Ashina",
        "Devlin",
        "Moreaux",
        "McCallister",
        "Zhang",
        "Malcolm",
        "Arem",
        "Selwyn",
        "Deckard",
        "Alvarez",
        "Silverhand",
        "Cunningham",
        "Smasher",
        "Amendiares",
        "Eurodyne",
        "Parker",
        "Palmer",
        "Hellman",
        "Yamada",
        "Parker",
        "Nishikata",
        "Arasaka",
        "Miyigawa",
        "Sato",
        "Obata",
        "Dixon",
        "Peralez",
        "Stout",
        "Anderson",
        "Akulov",
        "Summers",
        "Ward",
        "Wheeler",
        "Wang",
        "Dzeng",
        "Tsuru",
        "Packard",
        "McCoy",
        "Virek",
        "Turner",
        "Conroy",
        "Millions",
        "Newmark",
        "Mnemonic",
        "Case",
        "Corto",
        "Lee",
        "Riviera",
        "Pauly",
        "Tessier-Ashpool",
        "Deane",
        "Zone",
        "Yonderboy",
        "Krushkova",
        "Protagonist",
        "Ravinoff",
        "Marquez",
        "Rife",
        "Enzo",
        "Ryker"
        "Kovacs",
        "Bancroft",
        "Burroughs"
    ];

    string[] private firstName = [
        "Isobel",
        "Iggy",
        "Sapper",
        "Rick",
        "Leon",
        "Cleo",
        "Rhea",
        "Lilith",
        "Eldon",
        "Adam",
        "Anders",
        "Anna",
        "Judy",
        "ArthurBes",
        "Bryce",
        "Camila",
        "Carol",
        "Cassius",
        "Claire",
        "Dakota",
        "Dino",
        "Evelyn",
        "Fredrik",
        "Futoshi",
        "Hideyoshi",
        "Hiromi",
        "Haruyoshi",
        "Ishin",
        "Meredith",
        "Mikhail",
        "Mitch",
        "Peter",
        "Regina",
        "Rita",
        "Roger",
        "Rosalind",
        "Ruby",
        "Saburo",
        "Susan",
        "Theo",
        "Tom",
        "Wyatt",
        "William",
        "Zaria",
        "Hiro",
        "Josef",
        "Johnny",
        "Molly",
        "Henry",
        "Linda",
        "Willis",
        "Marie",
        "Lupus",
        "Bobby",
        "Marly",
        "Hiro",
        "Dmitri",
        "Juanita",
        "Takeshi"
        "Reileen"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getType(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TYPE", characterTypes);
    }

    function getOrigin(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ORIGIN", originCity);
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        string[2] memory name;
        name[0] = pluck(tokenId, "NAME", firstName);
        name[1] = pluck(tokenId, "SURNAME", lastName);
        return string(abi.encodePacked(name[0], " ", name[1]));
    }

    function getInt(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INTELLIGENCE", intelligence);
    }

    function getReflexes(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "REFLEXES", reflexes);
    }

    function getCool(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "COOL", cool);
    }

    function getTech(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "TECH", tech);
    }

    function getLuck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "LUCK", luck);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(output));
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: courier; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getName(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getType(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getOrigin(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getInt(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getReflexes(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getCool(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getTech(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getLuck(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Cyberpunk #', toString(tokenId), '", "description": "Cyberpunk Characters are randomized cyberpunk characters generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Cyberpunk Characters in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function cyberpunkHolderClaim() public nonReentrant {
        require(totalSupply() < TOTAL_MINTS);
        require(cyberpunkContract.balanceOf(msg.sender) > 0, "Must own Loot (for Cyberpunks)");
        uint256 index = totalSupply();
        _totalSupplyTracker.increment();
        _safeMint(_msgSender(), index);
    }

    function gearForPunksHolderClaim() public nonReentrant {
        require(totalSupply() < TOTAL_MINTS);
        require(gearContract.balanceOf(msg.sender) > 0, "Must own Gear (for Punks)");
        uint256 index = totalSupply();
        _totalSupplyTracker.increment();
        _safeMint(_msgSender(), index);
    }

    function publicClaim() public nonReentrant payable {
        require(totalSupply() < TOTAL_MINTS);
        require(msg.value == PUBLIC_MINT_PRICE);
        uint256 index = _totalSupply();
        _totalSupplyTracker.increment();
        _safeMint(_msgSender(), index);
    }

    function withdrawFunds() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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

    constructor() ERC721("Characters (for Cyberpunks)", "CYBRCHR") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}