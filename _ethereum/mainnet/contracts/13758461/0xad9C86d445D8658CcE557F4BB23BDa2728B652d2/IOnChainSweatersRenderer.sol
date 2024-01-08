// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./OnChainSweatersTypes.sol";

interface IOnChainSweatersRenderer {
    function tokenURI(uint256 tokenId, OnChainSweatersTypes.OnChainSweater memory sweater) external view returns (string memory);
    function getHQClaimedSweater(uint256 tokenId, OnChainSweatersTypes.OnChainSweater memory sweater, address tx) external view returns (string memory);
}