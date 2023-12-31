// SPDX-License-Identifier: MIT

/// @title TR Editions EA
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                              ◹◺
◹◺    ___________________________________________   _____       ◹◺
◹◺    \__    ___/\______   \_   _____/\_   _____/  /  _  \      ◹◺
◹◺      |    |    |       _/|    __)_  |    __)_  /  /_\  \     ◹◺
◹◺      |    |    |    |   \|        \ |        \/    |    \    ◹◺
◹◺      |____|    |____|_  /_______  //_______  /\____|__  /    ◹◺
◹◺                       \/        \/         \/         \/     ◹◺
◹◺                                                              ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract TrEditionsEa is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0xAa6AB798c96f347f079Dd2148d694c423aea8C81,
        "TR Editions EA",
        "TREEA",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
