// SPDX-License-Identifier: MIT

/// @title Dancing On The Graves Of The Right Click Saves
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                                                ◹◺
◹◺    |-----------------------------------------------------------------------|   ◹◺
◹◺    |    o   \ o /  _ o         __|    \ /     |__        o _  \ o /   o    |   ◹◺
◹◺    |   /|\    |     /\   ___\o   \o    |    o/    o/__   /\     |    /|\   |   ◹◺
◹◺    |   / \   / \   | \  /)  |    ( \  /o\  / )    |  (\  / |   / \   / \   |   ◹◺
◹◺    |-----------------------------------------------------------------------|   ◹◺
◹◺                                                                                ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract DancingOnTheGravesOfTheRightClickSaves is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Dancing On The Graves Of The Right Click Saves",
        "RTCLK",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
