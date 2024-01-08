// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./Math.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Contract8x8
 * 8x8 - All 2^64 unsigned 64-bit numbers, visualized in 8x8.
 * 8x8.page / https://www.18446744073709551615.com/
 */
contract Contract8x8 is ERC721Tradable, ReentrancyGuard {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("8x8", "8x8", _proxyRegistryAddress)
    {
        ownerPremint();
    }

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        string memory svg;
        svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" shape-rendering="crispEdges"><style>.b { fill: black; stroke-width: 1; stroke:#39ff14 }</style><rect width="400" height="400" fill="#39ff14" />';
        for (uint i=0; i<8; i++) {
            for (uint j=0; j<8; j++) {
                if ((((((tokenId ^ 0xffffffffffffffff) >> (i*8)) & (255)) >> j) & 1) > 0) {
                    svg = string(abi.encodePacked(svg, '<rect x="', Strings.toString(50*j), '" y="', Strings.toString(50*i), '" width="50" height="50" class="b"/>'));
                }
            }
        }
        string memory output = string(abi.encodePacked(svg, '</svg>'));        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', Strings.toString(tokenId), '", "description": "Hex: ', Strings.toHexString(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    // Run this to make sure the tokenId is not already minted and get the price in wei.
    function checkMintableAndGetPrice(uint256 tokenId) public view returns (uint256) {
        require(tokenId >= 1000 && tokenId < 18446744073709551615, "Token ID must be between 1000 and 2^64-2");
        require(!_exists(tokenId), "token already minted");
        return 1e15;
    }

    // Batch check up to 100 tokenIds.  Input must be sorted and deduped.
    function checkMintableAndGetPriceBatch(uint256[] memory sortedAndDedupedTokenIds) public view returns (uint256) {
        uint length = sortedAndDedupedTokenIds.length;
        require(length <= 100, "Maximum batch size of 100.");
        uint lastTokenId = 0; 
        for (uint i=0; i<length; i++) {
            require(i == 0 || (sortedAndDedupedTokenIds[i] > lastTokenId), "Token IDs must be sorted and deduped.");
            lastTokenId = sortedAndDedupedTokenIds[i];
            checkMintableAndGetPrice(sortedAndDedupedTokenIds[i]);
        }
        return 1e15 * length;
    }

    // Claim a token.  Requires payment in ETH.
    function claim(uint256 tokenId) public payable nonReentrant {
        uint256 price = checkMintableAndGetPrice(tokenId);
        require(msg.value >= price, "Insufficient payment. Try checkMintableAndGetPrice.");
        // send back change to sender if necessary.
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        _safeMint(_msgSender(), tokenId);
    }

    // Batch claim up to 100 tokenIds.  Input must be sorted and deduped.
    function claimBatch(uint256[] memory sortedAndDedupedTokenIds) public payable nonReentrant {
        uint length = sortedAndDedupedTokenIds.length;
        uint256 price = checkMintableAndGetPriceBatch(sortedAndDedupedTokenIds);
        require(msg.value >= price, "Insufficient payment. Try checkMintableAndGetPriceBatch");
        // send back change to sender if necessary.
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        for (uint i=0; i<length; i++) {
            _safeMint(_msgSender(), sortedAndDedupedTokenIds[i]);
        }
    }

    // Batch transfer up to 100 tokenIds.  Input must be sorted and deduped.
    function safeTransferFromBatch(address from, address to, uint256[] memory sortedAndDedupedTokenIds) public {
        uint length = sortedAndDedupedTokenIds.length;
        require(length <= 100, "Maximum batch size of 100.");
        uint lastTokenId = 0; 
        for (uint i=0; i<length; i++) {
            require(i == 0 || (sortedAndDedupedTokenIds[i] > lastTokenId), "Token IDs must be sorted and deduped.");
            lastTokenId = sortedAndDedupedTokenIds[i];
            safeTransferFrom(from, to, sortedAndDedupedTokenIds[i]);
        }
    }

    // For future release of range 1-999
    function ownerClaimBatch(uint256[] memory tokenIds) public nonReentrant onlyOwner {
        uint length = tokenIds.length;
        require(length <= 100, "Maximum batch size of 100.");
        for (uint i=0; i<length; i++) {
            if (tokenIds[i] < 1000 && !_exists(tokenIds[i])) {
                _safeMint(_msgSender(), tokenIds[i]);
            }
        }
    }

    function ownerPremint() internal nonReentrant onlyOwner {
        _safeMint(owner(), 0);
        _safeMint(owner(), 18446744073709551615);

        uint64[19] memory starter_ids = [
            3,4,5,
            153,
            3141592653589793238,
            7041776,
            12250000,
            4575627262464195387,
            2018180015695498240,
            14421692331585816576,
            326624360857600,
            2758816812967208448,
            12273903644374837845,
            4503546968848087056,
            18360838117716443136,
            54308144492113662,
            9183740411335607040,
            861051759064959,
            16059518366818242576
        ];

        uint8 length = uint8(starter_ids.length);
        for (uint8 i=0; i<length; i++) {
            _safeMint(owner(), starter_ids[i]);
        }
    }

    function sendBalance() public payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
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