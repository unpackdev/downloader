// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRetroCats {
    function ownerOf(uint256 tokenId) external returns (address owner);

    function s_tokenCounter() external returns (uint256);
}
