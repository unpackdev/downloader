// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./NFTArt.sol";
import "./base64.sol";

library NFTDescriptor {
    function constructTokenURI(
        uint256 tokenId,
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt,
        string memory collectionName
    ) internal pure returns (string memory) {
        string memory image = Base64.encode(NFTArt.drawSVG(result, ncol, nrow, salt));
        bytes memory metadata = abi.encodePacked(
            '{"name":"',
            collectionName,
            " #",
            uintToString(tokenId),
            '", "description":"',
            "Completely on-chain generative art collection. Art is uniquely generated based on the minter's result in our rebranding game. Limited edition. \\n\\nThe minter's result:\\n",
            makeSquares(result, ncol, nrow),
            '", "image": "',
            "data:image/svg+xml;base64,",
            image,
            '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function makeSquares(
        uint256 result,
        uint256 ncol,
        uint256 nrow
    ) internal pure returns (string memory) {
        unchecked {
            bytes[8] memory rows;
            for (uint256 q = 0; q < nrow; ++q) {
                string[8] memory strs;
                for (uint256 p = ncol - 1; p != type(uint256).max; --p) {
                    uint256 res = result % 3;
                    strs[p] = res == 0 ? hex"e2ac9cefb88f" : res == 1 ? hex"f09f9fa8" : hex"f09f9fa9";
                    result /= 3;
                }
                rows[q] = abi.encodePacked(strs[0], strs[1], strs[2], strs[3], strs[4], strs[5], strs[6], strs[7], "\\n");
            }
            return string(abi.encodePacked(rows[0], rows[1], rows[2], rows[3], rows[4], rows[5], rows[6], rows[7]));
        }
    }

    function makeImageURI(
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt
    ) internal pure returns (string memory) {
        string memory image = Base64.encode(NFTArt.drawSVG(result, ncol, nrow, salt));
        return string(abi.encodePacked("data:image/svg+xml;base64,", image));
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
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
