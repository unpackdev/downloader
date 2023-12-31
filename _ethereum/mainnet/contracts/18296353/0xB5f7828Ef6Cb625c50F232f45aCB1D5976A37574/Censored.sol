// SPDX-License-Identifier: MIT

/// @title CENSORED
/// @author transientlabs.xyz

/*??????????????????
??                ??
??    CENSORED    ??
??                ??
??????????????????*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Censored is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "CENSORED",
        "CNSRD",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
