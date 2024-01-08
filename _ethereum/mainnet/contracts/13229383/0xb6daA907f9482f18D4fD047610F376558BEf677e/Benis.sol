// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract Benis is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct BenisStruct {
        string balls;
        string shaft;
        string modification;
        string head;
        string cum;
        string name;
        string benisCum;
        string benisShaft;
        string color;
        uint256 length;
        uint256 cumLength;
    }

    // ɛ ʚ ȣ з § ß ჵ
    string[11] private ballParts = [
        "8",
        "B",
        "3",
        "g",
        "\xc9\x9b",
        "\xca\x9a",
        "\xc8\xa3",
        "\xd0\xb7",
        "\xc2\xa7",
        "\xc3\x9f",
        "\xe1\x83\xb5"
    ];
    // ᆖ ≈ ≡ ⏛ ⥤ ₪ ⇉ ≣ ☵
    string[11] private shaftParts = [
        "=",
        "\xe2\x81\x90",
        "\xe2\x89\x88",
        "\xe2\x89\xa1",
        "\xe1\x86\x96",
        "\xe2\x8f\x9b",
        "\xe2\xa5\xa4",
        "\xe2\x82\xaa",
        "\xe2\x87\x89",
        "\xe2\x89\xa3",
        "\xe2\x98\xb5"
    ];
    // ᑞ ᗚ Ϸ ᙐ ᙊ Ͻ ᕭ
    string[11] private headParts = [
        "D",
        "[}",
        ">",
        "[)",
        "\xe1\x91\x9e",
        "\xe1\x97\x9a",
        "\xcf\xb7",
        "\xe1\x99\x90",
        "\xe1\x99\x8a",
        "\xcf\xbd",
        "\xe1\x95\xad"
    ];
    // ÷ ֊ ؎ ᅳ ⟿ ― ⋯ ↝
    string[11] private cumParts = [
        "",
        "-",
        "~",
        "\xc3\xb7",
        "\xd6\x8a",
        "\xd8\x8e",
        "\xe1\x85\xb3",
        "\xe2\x9f\xbf",
        "\xe2\x80\x95",
        "\xe2\x8b\xaf",
        "\xe2\x86\x9d"
    ];
    // ᭷ ᭔ ⋮ “ ‘ ‡
    string[11] private modificationParts = [
        "",
        ".",
        ":",
        "*",
        "'",
        "\xe1\xad\xb7",
        "\xe1\xad\x94",
        "\xe2\x8b\xae",
        "\xe2\x80\x9c",
        "\xe2\x80\x98",
        "\xe2\x80\xa1"
    ];

    function getRandomPart(
        string[11] memory parts,
        uint256 tokenId,
        string memory partName
    ) internal pure returns (string memory) {
        uint256 partsLength = parts.length;
        uint256 rand = random(
            string(abi.encodePacked(toString(tokenId), partName))
        );
        uint256 partIndex = rand % (partsLength);

        return parts[partIndex];
    }

    constructor() ERC721("Benis", "CUM") {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getLength(uint256 tokenId, string memory prefix)
        public
        view
        returns (uint256)
    {
        require(
            _exists(tokenId),
            "You can only see the length of an existing benis."
        );
        uint256 rand = random(
            string(abi.encodePacked(prefix, toString(tokenId)))
        );
        uint256 length = (rand % 100);

        if (length < 25) return 1;
        if (length < 50) return 2;
        if (length < 75) return 3;
        if (length < 87) return 4;
        if (length < 93) return 5;
        if (length < 96) return 6;
        if (length < 99) return 7;
        return 8;
    }

    function getColor(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "You can only see the color of an existing benis."
        );
        uint256 rand = random(
            string(abi.encodePacked(toString(tokenId), "COLOR"))
        );
        uint256 length = (rand % 100);

        if (length < 35) return "lightgrey";
        if (length < 50) return "white";
        if (length < 65) return "lawngreen";
        if (length < 80) return "deepskyblue";
        if (length < 92) return "magenta";
        if (length < 99) return "orange";
        return "gold";
    }

    function createBenis(uint256 tokenId)
        internal
        view
        returns (BenisStruct memory)
    {
        if (tokenId == (random("BTC") % 6969)) {
            return
                BenisStruct(
                    "B",
                    "=",
                    "",
                    "TC",
                    "",
                    "B===TC",
                    "",
                    "===",
                    "yellow",
                    3,
                    0
                );
        }
        if (tokenId == (random("ETH") % 6969)) {
            return
                BenisStruct(
                    "E",
                    "=",
                    "",
                    "TH",
                    "",
                    "E===TH",
                    "",
                    "===",
                    "yellow",
                    3,
                    0
                );
        }
        if (tokenId == (random("DAO") % 6969)) {
            return
                BenisStruct(
                    "B",
                    "=",
                    "",
                    "Dao",
                    "",
                    "3===Dao",
                    "",
                    "===",
                    "yellow",
                    3,
                    0
                );
        }
        BenisStruct memory benis;
        benis.length = getLength(tokenId, "LENGTH");
        benis.cumLength = getLength(tokenId, "CUM");
        benis.balls = getRandomPart(ballParts, tokenId, "BALLS");
        benis.shaft = getRandomPart(shaftParts, tokenId, "SHAFT");
        benis.modification = getRandomPart(
            modificationParts,
            tokenId,
            "modification"
        );
        benis.head = getRandomPart(headParts, tokenId, "HEAD");
        benis.cum = getRandomPart(cumParts, tokenId, "CUM");
        benis.benisShaft = "";
        benis.benisCum = "";
        for (uint256 i = 0; i < benis.length; i++) {
            benis.benisShaft = string(
                abi.encodePacked(benis.benisShaft, benis.shaft)
            );
        }
        for (uint256 i = 0; i < benis.cumLength; i++) {
            benis.benisCum = string(
                abi.encodePacked(benis.benisCum, benis.cum)
            );
        }
        benis.color = getColor(tokenId);
        benis.name = string(
            abi.encodePacked(
                benis.balls,
                benis.benisShaft,
                benis.modification,
                benis.head,
                benis.benisCum
            )
        );
        if (keccak256(bytes(benis.cum)) == keccak256(bytes(""))) {
            benis.cumLength = 0;
        }

        return benis;
    }

    function generateImageData(BenisStruct memory benis)
        internal
        pure
        returns (string memory)
    {
        string[5] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="100%" height="100%" fill="black" /><text style="font-size:14px;" x="10" y="168" fill="';
        parts[1] = benis.color;
        parts[2] = '">';
        parts[3] = benis.name;
        parts[4] = "</text></svg>";

        return
            string(
                abi.encodePacked(
                    parts[0],
                    parts[1],
                    parts[2],
                    parts[3],
                    parts[4]
                )
            );
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        BenisStruct memory benis = createBenis(tokenId);
        return benis.name;
    }

    function generateAttributeMetadata(
        string memory trait,
        string memory value,
        bool isLast,
        bool isNumber
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    trait,
                    '","value":',
                    isNumber ? "" : '"',
                    value,
                    isNumber ? "" : '"',
                    "}",
                    isLast ? "" : ","
                )
            );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "You can only see an existing benis. You perve."
        );

        BenisStruct memory benis = createBenis(tokenId);
        string memory imageData = generateImageData(benis);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        benis.name,
                        '","description":"Did you ever want your own unique benis, directly on the blockchain? Here they cum.","image_data":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(imageData)),
                        '","attributes":[',
                        generateAttributeMetadata(
                            "Length",
                            toString(benis.length),
                            false,
                            true
                        ),
                        generateAttributeMetadata(
                            "Cum Length",
                            toString(benis.cumLength),
                            false,
                            true
                        ),
                        generateAttributeMetadata(
                            "Color",
                            benis.color,
                            false,
                            false
                        ),
                        generateAttributeMetadata(
                            "Balls",
                            benis.balls,
                            false,
                            false
                        ),
                        generateAttributeMetadata(
                            "Shaft",
                            benis.shaft,
                            false,
                            false
                        ),
                        generateAttributeMetadata(
                            "Head",
                            benis.head,
                            false,
                            false
                        ),
                        generateAttributeMetadata(
                            "Modification",
                            benis.modification,
                            false,
                            false
                        ),
                        generateAttributeMetadata(
                            "Cum",
                            benis.cum,
                            true,
                            false
                        ),
                        "]}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function claim() public nonReentrant {
        require(
            _tokenIdCounter.current() < 6969,
            "There can only be 6969 benisses."
        );
        _safeMint(_msgSender(), _tokenIdCounter.current());
        _tokenIdCounter.increment();
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
