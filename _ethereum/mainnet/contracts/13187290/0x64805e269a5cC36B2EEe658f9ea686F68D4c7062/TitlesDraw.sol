//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./Strings.sol";

contract TitlesDraw {
    using Strings for uint256;
    function getSvg(string memory name, string memory fColor, string memory bColor, bool isActive) public pure returns (string memory) {
        string[3] memory svgcomps;
        svgcomps[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 175"><style>.c{fill:' , fColor ,';font-family:Courier New;font-size:16px;font-weight:bold;} .i {fill:gray;text-decoration:line-through;}</style>'));
        
        if (isActive)            
            svgcomps[1] = string(abi.encodePacked('<rect width="100%" height="100%" style="fill:', bColor,';stroke-width:6;stroke:black"/><text class="c" x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">', name));
        else
            svgcomps[1] = '<rect width="100%" height="100%" style="fill:white;stroke-width:6;stroke:black"/><text class="c i" x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">Invalid Title';
        
        svgcomps[2] = '</text></svg>';

       return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(string(abi.encodePacked(svgcomps[0], svgcomps[1], svgcomps[2]))))));
    }

    function getRequirements(address[] memory titleAddresses, uint256[] memory titleMinAssets) public view returns (string memory) {
        string memory description = '';
        for (uint i=0; i<titleAddresses.length-1; i++) {
            description = string(abi.encodePacked(description, titleMinAssets[i].toString(), 'x ', IERC721Metadata(titleAddresses[i]).name(), ', '));
        }
        description = string(abi.encodePacked(description, titleMinAssets[titleAddresses.length-1].toString(), 'x ', IERC721Metadata(titleAddresses[titleAddresses.length-1]).name()));
        return description;
    }

   function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 35) return false; // Cannot be longer than 36 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space
        
        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(char == 0x3E || char == 0x3C)
                return false;

            lastChar = char;
        }

        return true;
    }

    function validateColor(string memory color) public pure returns (bool){
        bytes memory b = bytes(color);
        if(b.length < 3) return false;
        if(b.length > 20) return false; // Cannot be longer than 36 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space
        
        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if( char == 0x3E || 
                char == 0x3C ||
                char == 0x2F ||
                char == 0x3B ||
                char == 0x3A ||
                char == 0x7D ||
                char == 0x7B ||
                char == 0x3A
                )
                return false;

            lastChar = char;
        }

        return true;
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