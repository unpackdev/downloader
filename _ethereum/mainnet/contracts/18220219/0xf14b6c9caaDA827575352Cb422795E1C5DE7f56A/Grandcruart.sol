// SPDX-License-Identifier: MIT

/// @title GrandCruArt
/// @author transientlabs.xyz

/*/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
/\                                        /\
/\    ______                     __       /\
/\      / ____/________ _____  ____/ /    /\
/\     / / __/ ___/ __ `/ __ \/ __  /     /\
/\    / /_/ / /  / /_/ / / / / /_/ /      /\
/\    \____/_/___\__,_/_/ /_/\__,_/       /\
/\          / ____/______  __             /\
/\         / /   / ___/ / / /             /\
/\        / /___/ /  / /_/ /              /\
/\        \____/_/   \__,_/               /\
/\          /   |  _____/ /_              /\
/\         / /| | / ___/ __/              /\
/\        / ___ |/ /  / /_                /\
/\       /_/  |_/_/   \__/                /\
/\                                        /\
/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Grandcruart is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "GrandCruArt",
        "GCART",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
