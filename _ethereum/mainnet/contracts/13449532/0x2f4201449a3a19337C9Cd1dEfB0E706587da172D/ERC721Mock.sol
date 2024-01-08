// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./IERC721.sol";
import "./ERC721.sol";

contract ERC721Mock is ERC721("Mock", "MOCK") {
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external {
        _safeMint(to, tokenId, data);
    }

    function safeMintBatch0(
        address[] calldata to,
        uint256[] calldata tokenId,
        bytes memory data
    ) external {
        require(to.length == tokenId.length);
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], tokenId[i], data);
        }
    }

    function safeMintBatch1(
        address to,
        uint256[] calldata tokenId,
        bytes memory data
    ) external {
        for (uint256 i = 0; i < tokenId.length; i++) {
            _safeMint(to, tokenId[i], data);
        }
    }
}
