//SPDX-License-Identifier: Unlicense
/// @title: Quilts on-chain smart contract
/// @author: Quilt stitcher
/*
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
.                                                                              .
.                                 quilts.art                                   .
.                             We like the Quilts!                              .
.                                                                              .
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
.                                                                              .
.                                                                              .
.           =##%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%##=           .
.          :%%%%%%%%%%%+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*%%%%%%%%%%%%:          .
.        :#%%%%%%%%%%%+-%%%%%%%%%%%%%%+-%%%%%%%%%%%%%%+-%%%%%%%%%%%%%#.        .
.     -%%%%%%%%%%%%%%=--%%%%%%%%%%%%%=--%%%%%%%%%%%%%=--%%%%%%%%%%%%%+#%%-     .
.     %%%%%%%%%%%%%#=---%%%%%%%%%%%#=---%%%%%%%%%%%#=---%%%%%%%%%%%#=-%%%%     .
.     %%%%%%%%%%%%#-----%%%%%%%%%%#-----%%%%%%%%%%#-----%%%%%%%%%%#---%%%%     .
.     *%%%%%%%%%%*------%%%%%%%%%*------%%%%%%%%%*------%%%%%%%%%*----#%%*     .
.       %%%%%%%%*-------%%%%%%%%*-------%%%%%%%%*-------%%%%%%%%*-------       .
.       %%%%%%%+--------%%%%%%%+--------%%%%%%%+--------%%%%%%%+--------       .
.     *%%%%%%%+---------%%%%%%+---------%%%%%%+---------%%%%%%+-------*%%*     .
.     %%%%%%%=----------%%%%%=----------%%%%%=----------%%%%%=--------%%%%     .
.     %%%%%#=-----------%%%#=-----------%%%#=-----------%%%#=---------%%%%     .
.     %%%%#-------------%%#-------------%%#-------------%%#-----------%%%%     .
.     *%%*--------------%*--------------%*--------------%*------------*%%*     .
.       *---------------*---------------*---------------*---------------       .
.                                                                              .
.     *%%*                                                            *%%*     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     *%%*           -+**+-                          -+**+-           *%%*     .
.                   *%%%%%%*                        *%%%%%%*                   .
.                   *%%%%%%*                        *%%%%%%*                   .
.     *%%*           -+**+-                          -+**+-           *%%*     .
.     %%%%                                                            %%%%     .
.     %%%%                                                            %%%%     .
.     -%%*                                                            *%%-     .
.                                                                              .
.           *%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%*           .
.           =##%%%%+    +%%%%%%+    +%%%%%%+    +%%%%%%+    +%%%%##=           .
.                                                                              .
.                                                                              .
++++++ -  - - - - - - - - - - - - - - +++ - - - - - - - - - - - - - - - - ++++++
*/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./QuiltGenerator.sol";

contract Quilts is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 4000;
    uint256 public constant PRICE = 0.025 ether;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_ADDRESS = 20;
    uint256 public tokensMinted;
    bool public isSaleActive = false;
    bool public hasStitcherMinted = false;

    mapping(address => uint256) private _mintedPerAddress;

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId > 0 && tokenId <= tokensMinted, "Invalid token ID");

        // Get the quilt data and generated SVG
        QuiltGenerator.QuiltStruct memory quilt;
        string memory svg;
        (quilt, svg) = QuiltGenerator.getQuiltForSeed(
            Strings.toString(tokenId * 4444)
        );

        string[10] memory colorNames = [
            "Pink panther",
            "Cherry blossom",
            "Desert",
            "Forest",
            "Mushroom",
            "Mint tea",
            "Fairy grove",
            "Pumpkin",
            "Twilight",
            "Black & white"
        ];

        string[16] memory patchNames = [
            "Quilty",
            "Waterfront",
            "Flow",
            "Bengal",
            "Sunbeam",
            "Spires",
            "Division",
            "Crashing waves",
            "Equilibrium",
            "Ichimatsu",
            "Highlands",
            "Log cabin",
            "Maiz",
            "Flying geese",
            "Pinwheel",
            "Kawaii"
        ];

        string[4] memory backgroundNames = [
            "Dusty",
            "Flags",
            "Electric",
            "Groovy"
        ];

        string[4] memory calmnessNames = ["Serene", "Calm", "Wavey", "Chaotic"];

        // Make a list of the quilt patch names for metadata
        // Array `traits` are not supported by OpenSea, but other tools could
        // use this data for some interesting analysis.
        string memory patches;
        for (uint256 col = 0; col < quilt.patchXCount; col++) {
            for (uint256 row = 0; row < quilt.patchYCount; row++) {
                patches = string(
                    abi.encodePacked(
                        patches,
                        '"',
                        patchNames[quilt.patches[col][row]],
                        '"',
                        col == quilt.patchXCount - 1 &&
                            row == quilt.patchYCount - 1
                            ? ""
                            : ","
                    )
                );
            }
        }

        // Build metadata attributes
        string memory attributes = string(
            abi.encodePacked(
                '[{"trait_type":"Background","value":"',
                backgroundNames[quilt.backgroundIndex],
                '"},{"trait_type":"Animated background","value":"',
                quilt.animatedBg ? "Yes" : "No",
                '"},{"trait_type":"Theme","value":"',
                colorNames[quilt.themeIndex],
                '"},{"trait_type":"Background theme","value":"',
                colorNames[quilt.backgroundThemeIndex],
                '"},{"trait_type":"Patches","value":[',
                patches,
                ']},{"trait_type":"Special patch","value":"',
                quilt.includesSpecialPatch ? "Yes" : "No",
                '"},{"trait_type":"Patch count","value":',
                Strings.toString(quilt.patchXCount * quilt.patchYCount)
            )
        );

        attributes = string(
            abi.encodePacked(
                attributes,
                '},{"trait_type":"Aspect ratio","value":"',
                Strings.toString(quilt.patchXCount),
                ":",
                Strings.toString(quilt.patchYCount),
                '"},{"trait_type":"Calmness","value":"',
                calmnessNames[quilt.calmnessFactor - 1],
                '"},{"trait_type":"Hovers","value":"',
                quilt.hovers ? "Yes" : "No",
                '"},{"trait_type":"Roundness","value":',
                Strings.toString(quilt.roundness),
                "}]"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Quilt #',
                        Strings.toString(tokenId),
                        '","description":"Generative cozy quilts stitched on-chain and stored on the Ethereum network, forever.","attributes":',
                        attributes,
                        ',"image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function _claim(uint256 numTokens) private {
        require(totalSupply() < MAX_SUPPLY, "All quilts minted");
        require(
            totalSupply() + numTokens <= MAX_SUPPLY,
            "Minting exceeds max supply"
        );
        require(numTokens <= MAX_PER_TX, "Mint fewer quilts");
        require(numTokens > 0, "Must mint at least 1 quilt");
        require(
            _mintedPerAddress[_msgSender()] + numTokens <= MAX_PER_ADDRESS,
            "Exceeds wallet limit"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokensMinted + 1;
            _safeMint(_msgSender(), tokenId);
            tokensMinted += 1;
            _mintedPerAddress[_msgSender()] += 1;
        }
    }

    function claim(uint256 numTokens) public payable virtual {
        require(isSaleActive, "Sale not active");
        require(PRICE * numTokens == msg.value, "ETH amount is incorrect");
        _claim(numTokens);
    }

    function stitcherClaim() public onlyOwner {
        require(!hasStitcherMinted, "Stitcher already claimed quilts");
        _claim(10);
        hasStitcherMinted = true;
    }

    function toggleSale() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdrawAll() public payable nonReentrant onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    constructor() ERC721("Quilts", "QLTS") {}
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
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
