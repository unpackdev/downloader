// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HalloweenGhosts is ERC721Burnable, Ownable {

    using Strings for uint256;

    uint256[10] public halloweenStartTimestamps = [
    1635552000,
    1667088000,
    1698624000,
    1730246400,
    1761782400,
    1793318400,
    1824854400,
    1856476800,
    1888012800,
    1919548800
    ];

    uint256[10] public halloweenEndTimestamps = [
    1635724799,
    1667260799,
    1698796799,
    1730419199,
    1761955199,
    1793491199,
    1825027199,
    1856649599,
    1888185599,
    1919721599
    ];

    constructor(address to) ERC721("Halloween Ghosts", "HG") Ownable() {
        for (uint256 i = 0; i < 100; i++) {
            _safeMint(to, i);
        }
    }

    function generateMetadataJson(uint256 tokenId) public view returns (string memory) {
        string [31] memory parts;

        parts[0] = '{"name": "Halloween Ghosts #';
        parts[1] = tokenId.toString();
        parts[2] = '", ';
        parts[3] = '"description": ';
        parts[4] = '"Shhh...someone is knocking at your door. Trick or treat! Wow! A cute little ghost was there! What did your ghost look like?\\n\\n';
        parts[5] = 'Tx ID: [Czy3oiWsdx3SdCktImPq0aHTtQVFtwormO6ut4bwby8](https://arweave.net/Czy3oiWsdx3SdCktImPq0aHTtQVFtwormO6ut4bwby8?seed=';
        parts[6] = tokenId.toString();
        parts[7] = '&t=';
        parts[8] = block.timestamp.toString();
        parts[9] = '#';
        parts[10] = ')\\n\\n';
        parts[11] = 'License: [Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0)](https://creativecommons.org/licenses/by-nc-sa/3.0/)\\n\\n';
        parts[12] = 'Library: [p5.js](https://p5js.org/)\\n\\n';
        parts[13] = 'Artist SNS: [Twitter](https://twitter.com/senbaku), [OpenProcessing](https://openprocessing.org/user/207560/)", ';
        if (isNowHalloween()) {
            parts[14] = '"image": "ar://A17L0bueB1_AM1nUgDQp07UZIBnxDGAaQJkDT_6Vxe0/';
        } else {
            parts[14] = '"image": "ar://cTj0U8V6HcFqXH1Kycg1QKB6xzHblR_0mYbPsVtvF_I/';
        }
        parts[15] = tokenId.toString();
        parts[16] = '.png", ';
        parts[17] = '"animation_url": "ar://Czy3oiWsdx3SdCktImPq0aHTtQVFtwormO6ut4bwby8?seed=';
        parts[18] = tokenId.toString();
        parts[19] = '&t=';
        parts[20] = block.timestamp.toString();
        parts[21] = '#", ';
        parts[22] = '"external_url": "https://arweave.net/Czy3oiWsdx3SdCktImPq0aHTtQVFtwormO6ut4bwby8?seed=';
        parts[23] = tokenId.toString();
        parts[24] = '&t=';
        parts[25] = block.timestamp.toString();
        parts[26] = '#", ';
        parts[27] = '"origin_arweave_tx_id": "Czy3oiWsdx3SdCktImPq0aHTtQVFtwormO6ut4bwby8", ';
        parts[28] = '"attributes":[ { "trait_type":"Artist", "value":"senbaku" }, { "trait_type":"License", "value":"Attribution-NonCommercial-ShareAlike3.0Unported(CCBY-NC-SA3.0)" }, { "trait_type":"Library", "value":"p5.js" } ],';
        parts[29] = '"license_url": "https://creativecommons.org/licenses/by-nc-sa/3.0/"';
        parts[30] = '}';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[25],
                parts[26],
                parts[27],
                parts[28],
                parts[29],
                parts[30]
            )
        );

        return output;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(generateMetadataJson(tokenId))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function isNowHalloween() internal view returns (bool) {
        for (uint256 i = 0; i < halloweenStartTimestamps.length; i++) {
            if (halloweenStartTimestamps[i] <= block.timestamp && block.timestamp <= halloweenEndTimestamps[i]) {
                return true;
            }
        }

        return false;
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

