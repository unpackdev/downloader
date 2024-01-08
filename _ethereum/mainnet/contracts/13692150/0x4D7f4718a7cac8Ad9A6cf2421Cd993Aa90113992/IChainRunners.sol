// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC721Enumerable.sol";

interface IChainRunners is IERC721Enumerable {
    function getDna(uint256 _tokenId) external view returns (uint256);
}