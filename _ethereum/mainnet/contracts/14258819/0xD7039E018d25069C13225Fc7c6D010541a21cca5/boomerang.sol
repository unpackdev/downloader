//................................................................ 
//................................................................  
//.........................................,:----:,...............  
//.......................................:=+*++++=-:..............  
//....................................,-+***++++++=:,.............  
//..................................,=********++++-,..............  
//................................,=***+*****++++-,...............  
//..............................,=*****+++****+-:.................  
//............................,=***+*****++*+=:,..................  
//..........................,=**+++******++=:,....................  
//........................,=**++++*++****=:,......................  
//......................,=**+++++++++**+-,........................  
//....................,-***+++++++++*+-,..........................  
//...................:**++++++++++++-,............................  
//.................,+***++++++++++=:,.............................  
//................:***+++*+++++++-,...............................  
//...............:**+++++++++++=:,................................  
//..............:**++++**+++**+-,.................................  
//..............+*++++**+++***=:..................................  
//.............,****++***+++*+-:..................................  
//..............*****+**++**++=:..................................  
//..............=*****+++*****=-,.................................  
//..............,+*+*++++*****+=:,................................  
//...............,+*+++++*+****+=-,...............................  
//.................=*+++**++++++++-:,.............................  
//..................:+++**++++++**+=:,............................  
//....................=+*+++++++++**+-:,..........................  
//.....................,+*++++++++++**+-:,........................  
//.......................-**+++*++++++*+=-:,......................  
//.........................=**+***++++++*+=-,.....................  
//..........................,=***++++******+=:,...................  
//............................,+****+********+-:,.................  
//..............................,=*************=-,................  
//................................,=#**********#+-:,..............  
//..................................,=##****#####+-,..............  
//.....................................=#########*:,..............  
//.......................................-+#####+:,...............  
//.........................................,:,....................  
//................................................................  

// Morgan Ali 22-02-2022

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";

contract Boomerang is ERC721, ERC721URIStorage {

    constructor() ERC721("Boomerang", "BMRNG") {
      _safeMint(msg.sender, 1);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
         safeTransferFrom(
            from, 
            to, 
            tokenId,
            ""
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
         safeTransferFrom(
            from, 
            to, 
            tokenId,
            ""
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
         _safeTransfer(
            from, 
            to, 
            tokenId, 
            _data);
        _burn(tokenId);
        _safeMint(from, tokenId);
    }

    function ThrowBoomerang(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        safeTransferFrom(
            msg.sender, 
            to, 
            tokenId,
            _data
            );
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
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

    function tokenURI(uint256 tokenId) override(ERC721, ERC721URIStorage) pure public returns (string memory) {
            string[3] memory parts;

            parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"><style>.base { fill: black; font-family: monospace; font-size: 10px; }</style><rect width="100%" height="100%" fill="white" /><text x="0" y="0" class="base">';
            parts[1] = '<tspan dy="10px" x="0">..................................................................</tspan> <tspan dy="10px" x="0">..................................................................</tspan> <tspan dy="10px" x="0">.........................................,:----:,.................</tspan> <tspan dy="10px" x="0">.......................................:=+*++++=-:................</tspan> <tspan dy="10px" x="0">....................................,-+***++++++=:,...............</tspan> <tspan dy="10px" x="0">..................................,=********++++-,................</tspan> <tspan dy="10px" x="0">................................,=***+*****++++-,.................</tspan> <tspan dy="10px" x="0">..............................,=*****+++****+-:...................</tspan> <tspan dy="10px" x="0">............................,=***+*****++*+=:,....................</tspan> <tspan dy="10px" x="0">..........................,=**+++******++=:,......................</tspan> <tspan dy="10px" x="0">........................,=**++++*++****=:,........................</tspan> <tspan dy="10px" x="0">......................,=**+++++++++**+-,..........................</tspan> <tspan dy="10px" x="0">....................,-***+++++++++*+-,............................</tspan> <tspan dy="10px" x="0">...................:**++++++++++++-,..............................</tspan> <tspan dy="10px" x="0">.................,+***++++++++++=:,...............................</tspan> <tspan dy="10px" x="0">................:***+++*+++++++-,.................................</tspan> <tspan dy="10px" x="0">...............:**+++++++++++=:,..................................</tspan> <tspan dy="10px" x="0">..............:**++++**+++**+-,...................................</tspan> <tspan dy="10px" x="0">..............+*++++**+++***=:....................................</tspan> <tspan dy="10px" x="0">.............,****++***+++*+-:....................................</tspan> <tspan dy="10px" x="0">..............*****+**++**++=:....................................</tspan> <tspan dy="10px" x="0">..............=*****+++*****=-,...................................</tspan> <tspan dy="10px" x="0">..............,+*+*++++*****+=:,..................................</tspan> <tspan dy="10px" x="0">...............,+*+++++*+****+=-,.................................</tspan> <tspan dy="10px" x="0">.................=*+++**++++++++-:,...............................</tspan> <tspan dy="10px" x="0">..................:+++**++++++**+=:,..............................</tspan> <tspan dy="10px" x="0">....................=+*+++++++++**+-:,............................</tspan> <tspan dy="10px" x="0">.....................,+*++++++++++**+-:,..........................</tspan> <tspan dy="10px" x="0">.......................-**+++*++++++*+=-:,........................</tspan> <tspan dy="10px" x="0">.........................=**+***++++++*+=-,.......................</tspan> <tspan dy="10px" x="0">..........................,=***++++******+=:,.....................</tspan> <tspan dy="10px" x="0">............................,+****+********+-:,...................</tspan> <tspan dy="10px" x="0">..............................,=*************=-,..................</tspan> <tspan dy="10px" x="0">................................,=#**********#+-:,................</tspan> <tspan dy="10px" x="0">..................................,=##****#####+-,................</tspan> <tspan dy="10px" x="0">.....................................=#########*:,................</tspan> <tspan dy="10px" x="0">.......................................-+#####+:,.................</tspan> <tspan dy="10px" x="0">.........................................,:,......................</tspan> <tspan dy="10px" x="0">..................................................................</tspan>';
            parts[2] = '</text></svg>';

            string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Boomerang", "description": "transfer it, it comes back", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
            output = string(abi.encodePacked('data:application/json;base64,', json));

            tokenId = tokenId;

            return output;
        }

    function contractURI() public pure returns (string memory){
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Boomerang 2022", "description": "artwork generated directly on-chain from encoded SVG text / boomerang comes back each time you transfer it / coded and minted on a palindrome day 22-02-2022 by Morgan Ali"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
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






