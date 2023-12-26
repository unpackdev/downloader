// SPDX-License-Identifier: MIT

/// @title Biomechanical Muses
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                            ◹◺
◹◺    Biomechanical Muses by Nuwan Shilpa Hennayake           ◹◺
◹◺                                                            ◹◺
◹◺    Hallowed be the fusion of biomechanics and soul,        ◹◺
◹◺    Hallowed be the convergence of bits and atoms,          ◹◺
◹◺    Hallowed be the everlasting integration of existence.   ◹◺
◹◺                                                            ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract BiomechanicalMuses is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xD724c9223760278933A6F90c531e809Ec1Baca1c,
        "Biomechanical Muses",
        "MUSES",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
