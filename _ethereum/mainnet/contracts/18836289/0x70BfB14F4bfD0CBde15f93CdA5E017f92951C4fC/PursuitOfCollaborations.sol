// SPDX-License-Identifier: MIT

/// @title Pursuit of Collaborations
/// @author transientlabs.xyz



pragma solidity 0.8.19;

import "./TLCreator.sol";

contract PursuitOfCollaborations is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xD724c9223760278933A6F90c531e809Ec1Baca1c,
        "Pursuit of Collaborations",
        "POC",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
