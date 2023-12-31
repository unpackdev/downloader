// SPDX-License-Identifier: MIT

/// @title OMGiDRAWEDit Editions
/// @author transientlabs.xyz

/*//////////////////////
//                    //
//    OMGiDRAWEDit    //
//                    //
//////////////////////*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract OmgidraweditEditions is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xAa6AB798c96f347f079Dd2148d694c423aea8C81,
        "OMGiDRAWEDit Editions",
        "OMGE2",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
