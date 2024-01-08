// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomlyAssignedUpgradeable {
    function nextTokenId() external returns (uint256 tokenId);

    function getMaxSupply() external returns (uint256 maxSupply);

    event TokenIdCreated(uint256 indexed tokenId);
}
