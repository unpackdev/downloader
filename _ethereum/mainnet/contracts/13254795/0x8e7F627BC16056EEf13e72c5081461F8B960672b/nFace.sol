//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./NPassCore.sol";
import "./IN.sol";

/**
 * @title NFace
 * @author PoUpA Inspired by all the other N Derivatives projects
 */
contract NFace is NPassCore {
    using Strings for uint256;

    constructor(address _nContractAddress)
        NPassCore("NFace", "NFace", IN(_nContractAddress), true, 8888, 0, 10000000000000000, 0)
    {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" height="350" width="350"><defs><path id="l" stroke="#fff" fill="none" d="M 10,20 Q 50,';

        parts[1] = toString((n.getFirst(tokenId) * 10) + 5);

        parts[2] = ' 70,20 " /><path id="r" stroke="#fff" fill="none" d="M 0,20 Q 50,';

        parts[3] = toString((n.getSecond(tokenId) * 10) + 5);

        parts[4] = ' 80,20 " /><path id="n" stroke="#fff" fill="none" d="M 0,';

        parts[5] = toString(90 + n.getThird(tokenId));

        parts[6] = " C 75,";

        parts[7] = toString((n.getFourth(tokenId) + 7) * 10);

        parts[8] = ' -20,40 0,30" /><path id="m" stroke="#fff" fill="none" d="M-75,150 C -75,';

        parts[9] = toString((10 + n.getFifth(tokenId)) * 10);

        parts[10] = " 75,";

        parts[11] = toString((10 + n.getSixth(tokenId)) * 10);

        parts[12] = ' 75,150 " /><path id="c" stroke="#fff" fill="none" d="M-125,0 C -200,';

        parts[13] = toString((25 + n.getSeventh(tokenId)) * 10);

        parts[14] = " 150,";

        parts[15] = toString((20 + n.getEight(tokenId)) * 10);

        parts[
            16
        ] = ' 100,150 " /></defs><rect width="100%" height="100%" fill="#000" /><g transform="translate(175,75)"><use xlink:href="#l" /><use transform="translate(-100,0)" xlink:href="#r" /><use xlink:href="#n" /><use xlink:href="#m" /><use xlink:href="#c" /></g></svg>';

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

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "N Face #',
                        toString(tokenId),
                        '", "description": "N Face is just a face.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
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
