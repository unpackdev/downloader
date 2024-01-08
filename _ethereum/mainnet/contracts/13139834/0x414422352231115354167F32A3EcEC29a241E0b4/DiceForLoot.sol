// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract DiceForLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public price = 20000000000000000; //0.02 ETH

    //Loot Contract
    address public lootAddress = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    LootInterface public lootContract = LootInterface(lootAddress);

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirstDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 1);
    }

    function getSecondDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 2);
    }

    function getThirdDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 3);
    }

    function getFourthDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 4);
    }

    function getFifthDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 5);
    }

    function getSixthDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 6);
    }

    function getSeventhDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 7);
    }

    function getEighthDice(uint256 tokenId) public pure returns (uint256) {
        return roll(tokenId, 8);
    }

    function roll(uint256 _tokenId, uint256 _index)
        internal
        pure
        returns (uint256 output)
    {
        uint256 rand = random(string(abi.encodePacked(_tokenId, _index)));
        output = (rand % 6) + 1;
    }

    function outputCircleSVG(
        uint256 _x,
        uint256 _y,
        uint256 _r,
        string memory _color
    ) internal pure returns (string memory output) {
        string[7] memory parts;
        parts[0] = '<circle cx="';
        parts[1] = toString(_x);
        parts[2] = '" cy="';
        parts[3] = toString(_y);
        parts[4] = '" r="';
        // r
        parts[5] = '" fill="';
        // color
        parts[6] = '"/>';
        output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                toString(_r)
            )
        );
        output = string(abi.encodePacked(output, parts[5], _color, parts[6]));
    }

    function outputsDiceSVG(
        uint256 _num,
        uint256 _x,
        uint256 _y
    ) internal pure returns (string memory output) {
        string[12] memory parts;
        parts[0] = '<rect x="';
        parts[1] = toString(_x);
        parts[2] = '" y="';
        parts[3] = toString(_y);
        parts[
            4
        ] = '" width="24" height="24" fill="white" stroke="#ccc" stroke-width="1" rx="3" ry="3"/>';
        if (_num == 1) {
            parts[5] = outputCircleSVG(_x + 12, _y + 12, 3, "red");
        }
        if (_num >= 2) {
            parts[5] = outputCircleSVG(_x + 6, _y + 18, 2, "black");
            parts[6] = outputCircleSVG(_x + 18, _y + 6, 2, "black");
        }
        if (_num == 3 || _num == 5) {
            parts[7] = outputCircleSVG(_x + 12, _y + 12, 2, "black");
        }
        if (_num >= 4) {
            parts[8] = outputCircleSVG(_x + 6, _y + 6, 2, "black");
            parts[9] = outputCircleSVG(_x + 18, _y + 18, 2, "black");
        }
        if (_num == 6) {
            parts[10] = outputCircleSVG(_x + 6, _y + 12, 2, "black");
            parts[11] = outputCircleSVG(_x + 18, _y + 12, 2, "black");
        }
        output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[7],
                parts[8],
                parts[9],
                parts[10],
                parts[11]
            )
        );
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="black" />';
        parts[1] = outputsDiceSVG(getFirstDice(tokenId), 20, 20);
        parts[2] = outputsDiceSVG(getSecondDice(tokenId), 20, 50);
        parts[3] = outputsDiceSVG(getThirdDice(tokenId), 20, 80);
        parts[4] = outputsDiceSVG(getFourthDice(tokenId), 20, 110);
        parts[5] = outputsDiceSVG(getFifthDice(tokenId), 20, 140);
        parts[6] = outputsDiceSVG(getSixthDice(tokenId), 20, 170);
        parts[7] = outputsDiceSVG(getSeventhDice(tokenId), 20, 200);
        parts[8] = outputsDiceSVG(getEighthDice(tokenId), 20, 230);
        parts[9] = "</svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );

        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Dice for Loot #',
                        toString(tokenId),
                        '", "description": "Dice are randomly generated and stored on-chain. Total amounts and other features are intentionally omitted so that others can interpret them. The dice are free to use.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function mint(uint256 tokenId) public payable nonReentrant {
        require(tokenId > 8000 && tokenId <= 12000, "Token ID invalid");
        require(price <= msg.value, "Ether value sent is not correct");
        _safeMint(_msgSender(), tokenId);
    }

    function multiMint(uint256[] memory tokenIds) public payable nonReentrant {
        require(
            (price * tokenIds.length) <= msg.value,
            "Ether value sent is not correct"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIds[i] > 8000 && tokenIds[i] < 12000,
                "Token ID invalid"
            );
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function mintWithLoot(uint256 lootId) public payable nonReentrant {
        require(lootId > 0 && lootId <= 8000, "Token ID invalid");
        require(
            lootContract.ownerOf(lootId) == msg.sender,
            "Not the owner of this loot"
        );
        _safeMint(_msgSender(), lootId);
    }

    function multiMintWithLoot(uint256[] memory lootIds)
        public
        payable
        nonReentrant
    {
        for (uint256 i = 0; i < lootIds.length; i++) {
            require(
                lootContract.ownerOf(lootIds[i]) == msg.sender,
                "Not the owner of this loot"
            );
            _safeMint(_msgSender(), lootIds[i]);
        }
    }

    function withdraw() public onlyOwner {
        payable(0x63aEC545475b1b5F2e01B8812896c96fa0e0661f).transfer(
            address(this).balance
        );
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

    constructor() ERC721("Dice for Loot", "Dice") Ownable() {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
