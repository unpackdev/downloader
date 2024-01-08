//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract CHIMP is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Strings for uint8;

    uint256 public constant DIMENSION_SIZE = 16;
    uint256 public constant PALETTE_SIZE = 4;
    uint256 public constant PIXEL_CHUNKS = 2;

    struct ImageData {
        uint256[PIXEL_CHUNKS] pixelChunks;
        uint8[PALETTE_SIZE] colors;
        address author;
    }

    ImageData[] private tokenImages;

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

    bool public mintingActive = false;

    constructor() ERC721("CHIMP", "CHIMP") Ownable() {}

    function toggleActive() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mint(uint256[PIXEL_CHUNKS] memory pixelChunks, uint8[PALETTE_SIZE] memory colors) public payable nonReentrant {
        require(msg.value >= 0.02 ether, "Incorrect payment amount");
        require(mintingActive, "Minting is not currently active");

        for (uint8 i = 0; i < colors.length; ++i) {
            colors[i] = colors[i] % 52;
        }

        uint256 tokenId = totalSupply();

        ImageData memory data;
        data.colors = colors;
        data.pixelChunks = pixelChunks;
        data.author = msg.sender;
        tokenImages.push(data);

        _safeMint(_msgSender(), tokenId);
    }

    function imageDataForToken(uint256 tokenId) public view returns (ImageData memory) {
        require(_exists(tokenId), "SVG query for nonexistent token");
        return tokenImages[tokenId];
    }

    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "SVG query for nonexistent token");
        ImageData memory imageData = tokenImages[tokenId];

        string memory output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" shape-rendering="crispEdges" viewBox="0 0 ',
                DIMENSION_SIZE.toString(),
                ' ',
                DIMENSION_SIZE.toString(),
                '">'
            )
        );

        uint256 imagePixels;
        uint256 pixel = 0;
        for (uint i = 0; i < (DIMENSION_SIZE ** 2); i++) {
            if ((i % 128) == 0) {
                imagePixels = imageData.pixelChunks[PIXEL_CHUNKS - 1 - (i / 128)];
            }

            pixel = imagePixels & 3;
            imagePixels = imagePixels >> 2;
            output = string(
                abi.encodePacked(
                    output,
                    '<rect width="1.5" height="1.5" x="',
                    (i % DIMENSION_SIZE).toString(),
                    '" y="',
                    (i / DIMENSION_SIZE).toString(),
                    '" fill="',
                    palette[imageData.colors[pixel]],
                    '" />'
                )
            );
        }

        output = string(
            abi.encodePacked(
                output,
                '</svg>'
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
                        '{"name": "CHIMP #',
                        tokenId.toString(),
                        '", "description": "Pixel art generated using CHIMP: The On-Chain Image Manipulation Program.", "image": "',
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
