// SPDX-License-Identifier: MIT

/// @title OMGiDRAWEDit by OMGiDRAWEDit
/// @author transientlabs.xyz

/*??????????????????????
??                    ??
??    OMGiDRAWEDit    ??
??                    ??
??????????????????????*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Omgidrawedit is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "OMGiDRAWEDit",
        "OMG1E",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
