pragma solidity >=0.6.2;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

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

contract LootConditions is ERC721, ReentrancyGuard {
    address private _owner;
    uint256 public price = 10000000000000000; // 0.01 ETH
    uint256 public rarePrice = 500000000000000000; // 0.5 ETH

    LootInterface public lootContract;

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(address lootAddress) public ERC721("LootConditions", "LCOND") {
        address msgSender = _msgSender();
        _owner = msgSender;

        lootContract = LootInterface(lootAddress);
    }

    string[] private modifiers = [
        "+0",
        "+0",
        "+0",
        "+0",
        "+0",
        "+1",
        "+2",
        "+3",
        "+4",
        "+5",
        "+6",
        "+7",
        "+8",
        "+9",
        "+10",
        "+11",
        "+12",
        "+13",
        "+14",
        "+15",
        "+16",
        "+17",
        "+18",
        "+19",
        "+20",
        "-0",
        "-0",
        "-0",
        "-0",
        "-0",
        "-1",
        "-2",
        "-3",
        "-4",
        "-5",
        "-6",
        "-7",
        "-8",
        "-9",
        "-10",
        "-11",
        "-12",
        "-13",
        "-14",
        "-15",
        "-16",
        "-17",
        "-18",
        "-19",
        "-20"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        output = string(abi.encodePacked(keyPrefix, " ", modifiers[rand % modifiers.length]));

        return output;
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

    function mintCondition(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 8000 && tokenId <= 12000, "Token ID invalid");
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
        require((price * tokenIds.length) <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 8000 && tokenIds[i] <= 12000, "Token ID invalid");
            _safeMint(_msgSender(), tokenIds[i]);
        }
    }

    function multiMintWithLoot(uint256[] memory lootIds) public payable nonReentrant {
        for (uint256 i = 0; i < lootIds.length; i++) {
            require(lootContract.ownerOf(lootIds[i]) == msg.sender, "Not the owner of this loot");
            _safeMint(_msgSender(), lootIds[i]);
        }
    }

    function mintRareCondition(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 12000 && tokenId <= 12018, "Token ID invalid");
        require(rarePrice <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function getCondition(uint256 tokenId, string memory conditionName) public view returns (string memory) {
        return pluck(tokenId, conditionName, modifiers);
    }

    function isUltraRare(uint256 tokenId) public view returns (bool) {
        return (tokenId > 12000 && tokenId <= 12018);
    }

    function getRareAttribute(uint256 tokenId) public view returns (string memory) {
        require(tokenId > 12000 && tokenId <= 12018, "Token ID invalid");

        if (tokenId == 12001) {
            return "Strength: +1";
        } else if (tokenId == 12002) {
            return "Dexterity: +1";
        } else if (tokenId == 12003) {
            return "Constitution: +1";
        } else if (tokenId == 12004) {
            return "Intelligence: +1";
        } else if (tokenId == 12005) {
            return "Wisdom: +1";
        } else if (tokenId == 12006) {
            return "Vitality: +1";
        } else if (tokenId == 12007) {
            return "Luck: +1";
        } else if (tokenId == 12008) {
            return "Faith: +1";
        } else if (tokenId == 12009) {
            return "Charisma: +1";
        } else if (tokenId == 12010) {
            return "Strength: -1";
        } else if (tokenId == 12011) {
            return "Dexterity: -1";
        } else if (tokenId == 12012) {
            return "Constitution: -1";
        } else if (tokenId == 12013) {
            return "Intelligence: -1";
        } else if (tokenId == 12014) {
            return "Wisdom: -1";
        } else if (tokenId == 12015) {
            return "Vitality: -1";
        } else if (tokenId == 12016) {
            return "Luck: -1";
        } else if (tokenId == 12017) {
            return "Faith: -1";
        } else {
            return "Charisma: -1";
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (tokenId > 12000 && tokenId <= 12018) {
            string[3] memory parts;

            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

            parts[1] = getRareAttribute(tokenId);

            parts[2] = '</text></svg>';

            string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "LootCondition #', toString(tokenId), '", "description": "LootConditions are randomized modifers of Loot Ability Scores, generated and stored on chain. Other data and functionality is intentionally omitted for others to interpret. Feel free to use them in any way you want..", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

            return output;
        }

        string[20] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getCondition(tokenId, 'Strength:');

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getCondition(tokenId, 'Dexterity:');

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getCondition(tokenId, 'Constitution:');

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getCondition(tokenId, 'Intelligence:');

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getCondition(tokenId, 'Wisdom:');

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getCondition(tokenId, 'Charisma:');

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getCondition(tokenId, 'Vitality:');

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getCondition(tokenId, 'Luck:');

        parts[16] = '</text><text x="10" y="180" class="base">';

        parts[17] = getCondition(tokenId, 'Faith:');

        parts[19] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16], parts[17], parts[18], parts[19]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "LootCondition #', toString(tokenId), '", "description": "LootConditions are randomized modifers of Loot Ability Scores, generated and stored on chain. Other data and functionality is intentionally omitted for others to interpret. Feel free to use them in any way you want..", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}
