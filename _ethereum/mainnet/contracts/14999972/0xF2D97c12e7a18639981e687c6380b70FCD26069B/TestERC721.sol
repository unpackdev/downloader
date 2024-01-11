// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC721.sol";

contract TestERC721 is ERC721("TEST ERC721", "testerc721") {

    uint256 public minted;

    function mint(
        address to, uint256 tokenId
    ) public {
        minted = minted + 1;
        _mint(to, tokenId);
    }

    function batchMintToSingleAddress(
        address to, uint256[] memory tokenIds
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, tokenIds[i]);
        }
        minted = minted + tokenIds.length;
    }

    function batchMintToMultipleAddresses(
        address[] memory tos, uint256[] memory tokenIds
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(tos[i], tokenIds[i]);
        }
        minted = minted + tokenIds.length;
    }
}