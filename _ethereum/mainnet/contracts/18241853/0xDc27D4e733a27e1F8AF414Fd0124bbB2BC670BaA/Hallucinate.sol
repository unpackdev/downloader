// SPDX-License-Identifier: MIT

/// @title Hallucinate
/// @author transientlabs.xyz

/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
||                                                                                                      ||
||    Experience an apparent sensory perception of something that is not actually present in reality.   ||
||                                                                                                      ||
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Hallucinate is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Hallucinate",
        "HINFT",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
