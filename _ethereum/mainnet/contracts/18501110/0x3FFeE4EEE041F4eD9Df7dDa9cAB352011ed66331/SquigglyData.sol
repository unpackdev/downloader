// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
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

interface iSquiggly {
    function getIdToSVG(uint8 id) external view returns (string memory);
    function getIdToCreator(uint8 id) external view returns (address);
    function getIdToCurveType(uint8 id) external view returns (uint256);
}

pragma solidity 0.8.17;

contract SquigglyData {

    constructor() { 
        initializeAddress(0x36F379400DE6c6BCDF4408B282F8b685c56adc60);
    }
    
    using Strings for uint256;

    address public squigglyAddress; 
    iSquiggly squiggly; 

    function initializeAddress(address contractAddress) internal {
        squigglyAddress = contractAddress;
        squiggly = iSquiggly(squigglyAddress);
    }

    string svgJSON = '{"image_data": "'; //squiggly SVG;
    string idJSON = '","description": "Randomly generated and fully on-chain squiggly lines, the first project in the Atlantes series","external_url": "https://www.squiggly.wtf","name": "Squiggly '; //id;
    string creatorJSON = '","attributes": [{"trait_type": "created by","value": "'; //squiggly creator;
    string curveJSON = '"},{"trait_type": "curve type","value": "'; //squiggly curve type;
    string classJSON = '"},{"trait_type": "class type","value": "'; //squiggly class type;
    string endJSON = '"}]}';

    function tokenURI(uint256 id) public view returns (string memory) {  
        string memory encodedJSON;
        string memory dataURI;

        encodedJSON = Base64.encode(bytes(tokenJSON(id)));
        dataURI = string(abi.encodePacked('data:application/json;base64,', encodedJSON));

        return dataURI;
    }

    function renderSquiggly(uint256 id) public view returns (string memory) {
        uint8 id8 = uint8(id);
        string memory squigglySVG;

        squigglySVG = string(abi.encodePacked('<?xml version="1.0" encoding="UTF-8"?>',squiggly.getIdToSVG(id8)));

        return squigglySVG;
    }

    function tokenJSON(uint256 id) public view returns (string memory) {
        uint8 id8 = uint8(id);
        string memory JSON;

        JSON = string(abi.encodePacked(svgJSON, squiggly.getIdToSVG(id8)));
        JSON = string(abi.encodePacked(JSON, idJSON, id.toString()));
        JSON = string(abi.encodePacked(JSON, creatorJSON, Strings.toHexString(uint256(uint160(squiggly.getIdToCreator(id8))), 20)));
        JSON = string(abi.encodePacked(JSON, curveJSON, translateCurveType(squiggly.getIdToCurveType(id8))));
        JSON = string(abi.encodePacked(JSON, classJSON, getClass(id), endJSON));

        return JSON;        
    }

    function translateCurveType(uint256 curveType) public pure returns (string memory curveTypeString) {
        if (curveType == 1){
            curveTypeString = "C Curve";
        }
        else if (curveType == 2){
            curveTypeString = "S Curve";
        }
        else if (curveType == 3){
            curveTypeString = "Q Curve";
        }
        else if (curveType == 4){
            curveTypeString = "T Curve";
        }
        else {
            curveTypeString = "No Curve";
        }        
    }

    function getClass(uint256 id) public pure returns (string memory classType) {
        if (id <= 4){
            classType = "Promo";
        }
        else {
            classType = "Standard";
        }
    }
    
}