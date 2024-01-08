//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

interface CHIMPContract is IERC721 {
    struct ImageData {
        uint256[2] pixelChunks;
        uint8[4] colors;
        address author;
    }

    function imageDataForToken(uint256 tokenId) external view returns (ImageData memory);
}

interface AdventureCardsContract is IERC721 {
    function getCardTitle(uint256 tokenId, uint256 offset) external view returns (string memory);
}

contract CHIMPCards is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Strings for uint8;

    string[52] public palette = [
    "#00237C",
    "#0B53D7",
    "#51A5FE",
    "#B5D9FE",
    "#0D1099",
    "#3337FE",
    "#8084FE",
    "#CACAFE",
    "#300092",
    "#6621F7",
    "#BC6AFE",
    "#E3BEFE",
    "#4F006C",
    "#9515BE",
    "#F15BFE",
    "#F9B8FE",
    "#600035",
    "#AC166E",
    "#FE5EC4",
    "#FEBAE7",
    "#5C0500",
    "#A62721",
    "#FE7269",
    "#FEC3BC",
    "#461800",
    "#864300",
    "#E19321",
    "#F4D199",
    "#272D00",
    "#596200",
    "#ADB600",
    "#DEE086",
    "#093E00",
    "#2D7A00",
    "#79D300",
    "#C6EC87",
    "#004500",
    "#0C8500",
    "#51DF21",
    "#B2F29D",
    "#004106",
    "#007F2A",
    "#3AD974",
    "#A7F0C3",
    "#003545",
    "#006D85",
    "#39C3DF",
    "#A8E7F0",
    "#000000",
    "#424242",
    "#A1A1A1",
    "#FFFFFF"
    ];

    CHIMPContract private chimpContract;
    AdventureCardsContract private cardsContract;

    mapping(uint256 => bool) private chimpRedemptions;
    mapping(bytes32 => bool) private cardRedemptions;
    mapping(bytes32 => uint256) public editionCount;

    struct CardData {
        uint256 chimpId;
        uint256 packId;
        uint256 cardOffset;
        uint256 edition;
    }

    CardData[] private tokenData;

    constructor(address _chimpContractAddress, address _cardsContractAddress) ERC721("CHIMPCards", "CHIMPCards") Ownable() {
        cardsContract = AdventureCardsContract(_cardsContractAddress);
        chimpContract = CHIMPContract(_chimpContractAddress);
    }

    function chimpAvailable(uint256 chimpId) public view returns (bool) {
        return !chimpRedemptions[chimpId];
    }

    function cardAvailable(uint256 packId, uint256 cardOffset) public view returns (bool) {
        bytes32 cardHash = keccak256(abi.encodePacked(packId, cardOffset));
        return !cardRedemptions[cardHash];
    }

    function mint(uint256 chimpId, uint256 packId, uint256 cardOffset) public nonReentrant {
        require(chimpRedemptions[chimpId] == false, "CHIMP already redeemed");
        require(_msgSender() == chimpContract.ownerOf(chimpId), "CHIMP not owned");

        require(_msgSender() == cardsContract.ownerOf(packId), "Adventure Card not owned");
        bytes32 cardHash = keccak256(abi.encodePacked(packId, cardOffset));
        require(cardRedemptions[cardHash] == false, "Adventure Card already redeemed");

        string memory cardName = cardsContract.getCardTitle(packId, cardOffset);
        bytes32 cardNameHash = keccak256(abi.encodePacked(cardName));

        uint256 tokenId = totalSupply();

        CardData memory data;
        data.chimpId = chimpId;
        data.packId = packId;
        data.cardOffset = cardOffset;
        editionCount[cardNameHash]++;
        data.edition = editionCount[cardHash];

        tokenData.push(data);

        chimpRedemptions[chimpId] = true;
        cardRedemptions[cardHash] = true;

        _safeMint(_msgSender(), tokenId);
    }

    function cardDataForToken(uint256 tokenId) public view returns (CardData memory) {
        require(_exists(tokenId));
        return tokenData[tokenId];
    }


    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "SVG query for nonexistent token");
        CardData memory cardData = tokenData[tokenId];
        CHIMPContract.ImageData memory imageData = chimpContract.imageDataForToken(cardData.chimpId);

        string memory output = '<svg width="299" height="340" viewBox="0 0 315 358" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg"><style>.b { font-family: serif; font-weight: bold; font-size: 13px; } .e { font-family: serif; font-size: 11px; }</style><rect width="315" height="358" fill="#F6C104"/><rect x="8" y="8" width="299" height="342" rx="8" fill="black"/>';

        uint256 imagePixels;
        uint256 pixel = 0;
        for (uint i = 0; i < (16 ** 2); i++) {
            if ((i % 128) == 0) {
                imagePixels = imageData.pixelChunks[2 - 1 - (i / 128)];
            }

            pixel = imagePixels & 3;
            imagePixels = imagePixels >> 2;
            output = string(
                abi.encodePacked(
                    output,
                    '<rect width="16.5" height="16.5" x="',
                    (28 + (16 * (i % 16))).toString(),
                    '" y="',
                    (28 + (16 * (i / 16))).toString(),
                    '" fill="',
                    palette[imageData.colors[pixel]],
                    '" />'
                )
            );
        }

        output = string(
            abi.encodePacked(
                output,
                '<text x="28" y="315" fill="#fff" class="b">',
                cardsContract.getCardTitle(cardData.packId, cardData.cardOffset),
                '</text><text x="28" y="332" fill="#fff" class="e">Edition #',
                (cardData.edition + 1).toString(),
                '</text></svg>'
            )
        );
        return output;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory output = tokenSVG(tokenId);

        output = string(abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(bytes(output))
            ));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "CHIMP Card #',
                        tokenId.toString(),
                        '", "description": "CHIMP based cards for the Adventure Cards project.", "image": "',
                        output,
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }
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
