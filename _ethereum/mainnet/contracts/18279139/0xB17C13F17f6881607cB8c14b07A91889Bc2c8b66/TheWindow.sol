// SPDX-License-Identifier: MIT

/// @title The Window
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                            ◹◺
◹◺    HHHHHHHHHHHHHHHHHHHHH   ◹◺
◹◺    HHHHHHHHHHHHHHHHHHHHH   ◹◺
◹◺    HHH       H       HHH   ◹◺
◹◺    HHH       H       HHH   ◹◺
◹◺    HHHHHHHHHHHHHHHHHHHHH   ◹◺
◹◺    HHH       H       HHH   ◹◺
◹◺    HHH       H       HHH   ◹◺
◹◺    HHHHHHHHHHHHHHHHHHHHH   ◹◺
◹◺    HHH               HHH   ◹◺
◹◺    HHH               HHH   ◹◺
◹◺    HHH               HHH   ◹◺
◹◺    HHHHHHHHHHHHHHHHHHHHH   ◹◺
◹◺    HHHHHHHHHHHHHHHHHHHHH   ◹◺
◹◺                            ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract TheWindow is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "The Window",
        "WIND",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
