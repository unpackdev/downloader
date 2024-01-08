// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";

/*
    https://twitter.com/_n_collective


*/
contract PythagoreanScholars is ERC721, Ownable, ReentrancyGuard, ERC721Holder {

    mapping(uint256 => string) public tokenNames;
    mapping(uint256 => string) public tokenDescriptions;
    mapping(uint256 => string) public tokenAttributes;
    mapping(uint256 => string) public tokenSVGs;
    uint256 public totalSupply;

    constructor() ERC721("Pythagorean Scholars", "PythagoreanScholars") {}

    function mintToken(
        uint256 tokenId,
        address to,
        string memory name,
        string memory description,
        string memory attributes,
        string memory svg
    ) onlyOwner nonReentrant external {
        require(to != address(0), "Wut?");
        require(bytes(svg).length != 0, "SVG cannot be empty");
        tokenNames[tokenId] = name;
        tokenDescriptions[tokenId] = description;
        tokenAttributes[tokenId] = attributes;
        tokenSVGs[tokenId] = svg;
        _mint(to, tokenId);
        totalSupply++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        string memory json = Base64._encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        tokenNames[tokenId],
                        '", "description": "',
                        tokenDescriptions[tokenId],
                        '", "image": "data:image/svg+xml;base64,',
                        Base64._encode(bytes(tokenSVGs[tokenId])),
                        '", "attributes": [',
                        tokenAttributes[tokenId],
                        ']}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));

        return json;
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function _encode(bytes memory data) internal pure returns (string memory) {
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