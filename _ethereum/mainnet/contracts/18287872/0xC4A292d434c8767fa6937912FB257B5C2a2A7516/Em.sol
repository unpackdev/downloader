// SPDX-License-Identifier: MIT

/// @title EM!
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                            ◹◺
◹◺    ▀███▀▀▀███    ▀████▄     ▄███▀   ██     ◹◺
◹◺      ██    ▀█      ████    ████     ██     ◹◺
◹◺      ██   █        █ ██   ▄█ ██     ██     ◹◺
◹◺      ██████        █  ██  █▀ ██     ██     ◹◺
◹◺      ██   █  ▄     █  ██▄█▀  ██     ▀▀     ◹◺
◹◺      ██     ▄█     █  ▀██▀   ██     ▄▄     ◹◺
◹◺    ▄██████████   ▄███▄ ▀▀  ▄████▄   ██     ◹◺
◹◺                                            ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Em is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xAa6AB798c96f347f079Dd2148d694c423aea8C81,
        "EM!",
        "EMI",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
