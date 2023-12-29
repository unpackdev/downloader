// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IXENFTMinimal {
    function bulkClaimMintReward(uint256 tokenId, address dest) external;
}