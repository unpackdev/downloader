// SPDX-License-Identifier: MIT

/// @title The Bitcoin Cowgirl
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                                                      ◹◺
◹◺    The Bitcoin Cowgirl.....                                                          ◹◺
◹◺                                                                                      ◹◺
◹◺    She first appeared above the sky....                                              ◹◺
◹◺                                                                                      ◹◺
◹◺    She rallied hope from within us all.                                              ◹◺
◹◺                                                                                      ◹◺
◹◺    She feared no man.                                                                ◹◺
◹◺                                                                                      ◹◺
◹◺    She has multiple enemies.                                                         ◹◺
◹◺                                                                                      ◹◺
◹◺    Up and down, she continues to fight for justice and what is right in the world.   ◹◺
◹◺                                                                                      ◹◺
◹◺    Many label her a villain, a thief of sorts.                                       ◹◺
◹◺                                                                                      ◹◺
◹◺    Some say she is the new law in these parts.                                       ◹◺
◹◺                                                                                      ◹◺
◹◺    To steal from the rich, and give to the poor.                                     ◹◺
◹◺                                                                                      ◹◺
◹◺    She has been beat up, shot at, even put down.                                     ◹◺
◹◺                                                                                      ◹◺
◹◺    Rising again from the ashes, she is a unlikely savior....                         ◹◺
◹◺                                                                                      ◹◺
◹◺    She is our new religion, our new spirit, she is all of us in this battle...       ◹◺
◹◺                                                                                      ◹◺
◹◺    She will never give up.  Dont you give up on her.                                 ◹◺
◹◺                                                                                      ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract TheBitcoinCowgirl is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "The Bitcoin Cowgirl",
        "COWG",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
