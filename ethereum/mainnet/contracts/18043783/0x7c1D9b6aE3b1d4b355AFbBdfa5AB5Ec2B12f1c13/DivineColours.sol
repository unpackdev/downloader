// SPDX-License-Identifier: MIT

/// @title Divine Colours by tjo
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                                                                            ◹◺
◹◺    ◉◉◉◉◉◉◉◉◉                ◉◉◉◉◉◉                                                                         ◹◺
◹◺                                  ◦◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉          ◉◉◉◉◉◉◉◉◉◉◉◉                                    ◹◺
◹◺                                ◦◦    ◉◉◉◉◉◉◉◉◉◉◉◉◉        ◉◉◉◉◉◉◉◉◉◉◉◉◉◉◉                                  ◹◺
◹◺                              ◦◉      ◉◉◉◉◉◉◉◉◉◉◉◉◉        ◉◉◉◉◉◉◉◉◉◉◉◉◉ ◉◉                                 ◹◺
◹◺                             ◦◉         ◉◉◉◉◉◉◉◉◉          ◉◉◉◉◉◉◉◉◉◉◉◉   ◉◉                                ◹◺
◹◺                             ◉                                ◉◉◉◉◉◉       ◉                                ◹◺
◹◺                             ◉                                             ◉◉                               ◹◺
◹◺                             ◉                                             ◉◉                               ◹◺
◹◺                             ◉                                             ◉                                ◹◺
◹◺                             ◦◉                                           ◉                                 ◹◺
◹◺                              ◦◉                                                                            ◹◺
◹◺                               ◦◉                                       ◉                                   ◹◺
◹◺                                 ◉                                    ◉                                     ◹◺
◹◺                                  ◦◉                                                                        ◹◺
◹◺                                     ◉                                                                      ◹◺
◹◺                                        ◦◦                                                                  ◹◺
◹◺                                            ◦◦                   ◉◦                                         ◹◺
◹◺                                                                                                            ◹◺
◹◺                                                                                                            ◹◺
◹◺                                                                                                            ◹◺
◹◺                                                                                                            ◹◺
◹◺                                                                                                            ◹◺
◹◺                              ■■■■■■■■■■■■     ■■■■■■■■■■■■      ■■■■■■■■■■■■                               ◹◺
◹◺                              ■■■■■■■■■■■■     ■■■■■■■■■■■■      ■■■■■■■■■■■■                               ◹◺
◹◺                              ■■■■■■■■■■■■     ■■■■■■■■■■■■      ■■■■■■■■■■■■                               ◹◺
◹◺                              ■■■■■■■■■■■■     ■■■■■■■■■■■■      ■■■■■■■■■■■■                               ◹◺
◹◺                                                                                                            ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract DivineColours is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Divine Colours",
        "CLRS",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
