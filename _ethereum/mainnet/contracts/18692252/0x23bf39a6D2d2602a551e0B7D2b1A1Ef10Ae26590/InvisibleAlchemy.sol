// SPDX-License-Identifier: MIT

/// @title Invisible Alchemy
/// @author transientlabs.xyz

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract InvisibleAlchemy is TLCreator {

    constructor(
        string memory name,
        string memory symbol,
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address initOwner,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    ) TLCreator(
        0x2eb9B14677Df35998A4393cDefab352b526239eB , // ETH
        // 0x68920FB653c57730b8eb7E61F72aC67C3D2Dfe5d, // GOERLI
        // 0x7eFF56e3dBEb5ec6056Da79b70281Efba295d7B7, // ARBITRUM ONE
        // 0xc192C96aE16E81a06cA4e52046C8c79aBAd63EB9, // ARBITRUM GOERLI
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