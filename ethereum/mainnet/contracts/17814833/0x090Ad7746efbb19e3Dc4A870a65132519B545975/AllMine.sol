// SPDX-License-Identifier: MIT

/// @title It's Mine, Mine All Mine
/// @author transientlabs.xyz

pragma solidity 0.8.19;

import "./Doppelganger.sol";

contract AllMine is Doppelganger {

    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) Doppelganger(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2, // ETH
        // 0x403201aC548dba0e889148137dab984b71230F6c, // GOERLI
        // 0x0E841ae8f9CCDa3bDC14780216B974a477978Fec, // ARBITRUM ONE
        // 0x00059878282ec217c761F20e668932D1A7f3bb97, // ARBITRUM GOERLI
        name,
        symbol,
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        initOwner,
        admins,
        enableStory,
        blockListRegistry
    ) {}
}