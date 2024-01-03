// SPDX-License-Identifier: MIT

/// @title FACES OF CRYPTO ART
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                      ◹◺
◹◺    FACES OF CRYPTO ART // BY MLow    ◹◺
◹◺                                      ◹◺
◹◺    :)                                ◹◺
◹◺                                      ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract FacesOfCryptoArt is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xD724c9223760278933A6F90c531e809Ec1Baca1c,
        "FACES OF CRYPTO ART",
        "FOCA",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
