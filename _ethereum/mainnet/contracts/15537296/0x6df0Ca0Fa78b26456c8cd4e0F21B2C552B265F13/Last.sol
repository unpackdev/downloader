// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract Last is ERC721, ERC721Burnable, Ownable, ReentrancyGuard {

    constructor() ERC721("The Last PoW NFT", "LAST") {
        _safeMint(msg.sender, 0);
    }

    uint256 currentToken;

    function mint() public nonReentrant {
        require(block.difficulty < 2**64 && block.difficulty > 0);
        _burn(currentToken);
		currentToken++;
        _safeMint(msg.sender, currentToken);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
                '{"name": "The Last PoW NFT", "description": "Minting can only be accessed before the Ethereum Merge TTD and each mint burns the previous token. Good luck.","image": "data:image/svg+xml;base64,',
                Base64.encode(bytes('<?xml version="1.0" encoding="UTF-8"?> <svg style="background-color:#fff" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg"> <style>.title{fill:Black;font-size:20px;font-family:Courier}}</style> <text class="title" x="50%" y="50%" dominant-baseline="middle" text-anchor="middle">the last proof of work nft</text> <svg x="25%" y="25%" width="50%" height="50%" fill="#010101" opacity=".05" viewBox="-2.75,-2.75 98 156"> <path d="m46.221 55.684-46.221 21.009 46.221 27.321 46.221-27.321-46.221-21.009z" opacity=".60001"/> <path d="m3.7e-4 76.692 46.221 27.321v-48.33-55.684l-46.221 76.692z" opacity=".45"/> <path d="m46.221 0v55.684 48.33l46.221-27.321-46.221-76.692z" opacity=".8"/> <path d="m3.7e-4 85.457 46.221 65.134v-37.826l-46.221-27.308z" opacity=".45"/> <path d="m46.221 112.77v37.826l46.249-65.134-46.249 27.308z" opacity=".8"/> </svg> </svg>')),
                '"}'
            ))));
        return string(abi.encodePacked('data:application/json;base64,',json));
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
