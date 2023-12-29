// SPDX-License-Identifier: MIT

/// @title ERC721 Implementation of Whoopsies v2 Collection
pragma solidity ^0.8.21;

/// @custom:security-contact captainunknown7@gmail.com
interface IWhoopsiesV2 {
    function claimV2NFTs(uint256[] calldata requestedTokenIds) external;
    function toggleV2ClaimActive() external;
}