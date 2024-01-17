// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";

///////////////////////////////////////////////////////////////////////////////////
//                                                                               //
//                           __         __    __       __                        //
//    .----.----.--.--.-----|  |_.-----|  |--|__.-----|  |_.-----.----.--.--.    //
//    |  __|   _|  |  |  _  |   _|  _  |     |  |__ --|   _|  _  |   _|  |  |    //
//    |____|__| |___  |   __|____|_____|__|__|__|_____|____|_____|__| |___  |    //
//              |_____|__|                                            |_____|    //
//                                                                               //
///////////////////////////////////////////////////////////////////////////////////

/// @title cryptohistory
contract cryptohistory is ERC721 {
    //
    constructor() ERC721("cryptohistory", "ch") {
        _mint(address(this), 1);
    }

    function tokenURI(uint256 tokenID_) public view virtual override returns (string memory) {
        string memory svg =
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 11px; }</style><rect width="100%" height="100%" fill="black" /><text x="11" y="22" class="base">cryptohistory 2022</text></svg>';
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "cryptohistory", "description": "cryptohistory 2022", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '", "attributes": {"timestamp": "1668244271"}, "content": {"mimeType": "text/plain", "hash": "3005488e8f60e7471537ad8aa74f50a0b8023f553549291d36ef4b4e5c348cfd", "uri": ""}}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    //
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

            for { let i := 0 } lt(i, len) {} {
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
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
