// SPDX-License-Identifier: MIT

/// @title yungwknd
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                ◹◺
◹◺    yungwknd    ◹◺
◹◺                ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Yungwknd is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xAa6AB798c96f347f079Dd2148d694c423aea8C81,
        "yungwknd",
        "YUNG",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
