// SPDX-License-Identifier: MIT

/// @title END GAME VIGNETTES by The Mike Elf
/// @author transientlabs.xyz

/*??????????????????????
??                    ??
??    e/\/d           ??
??    ga/\/\e         ??
??    vig/\/ettes     ??
??                    ??
??    e/\/d           ??
??    ga/\/\e         ??
??    vig/\/ettes     ??
??                    ??
??    e/\/d           ??
??    ga/\/\e         ??
??    vig/\/ettes     ??
??                    ??
??????????????????????*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract EndGameVignettes is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "END GAME VIGNETTES",
        "END",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
