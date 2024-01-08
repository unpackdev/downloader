// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";

interface IChains is IERC721Enumerable {

    function getTokenTimestamp(uint256 _tokenId)
        external
        view
        returns (uint256);

    function getTokenRarityCount(uint256 _tokenId)
        external
        view
        returns (uint256);

    function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);
}
