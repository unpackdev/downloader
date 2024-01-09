// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IChainRunners {
    function getDna(uint256 _tokenId) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}
