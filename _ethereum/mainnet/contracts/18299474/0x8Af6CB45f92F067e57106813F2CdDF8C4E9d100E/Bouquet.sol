// SPDX-License-Identifier: MIT

/// @title Bouquet
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                                        ◹◺
◹◺    _                                                                   ◹◺
◹◺                      _(_)_                          wWWWw   _          ◹◺
◹◺          @@@@       (_)@(_)   vVVVv     _     @@@@  (___) _(_)_        ◹◺
◹◺         @@()@@ wWWWw  (_)\    (___)   _(_)_  @@()@@   Y  (_)@(_)       ◹◺
◹◺          @@@@  (___)     `|/    Y    (_)@(_)  @@@@   \|/   (_)\        ◹◺
◹◺           /      Y       \|    \|/    /(_)    \|      |/      |        ◹◺
◹◺        \ |     \ |/       | / \ | /  \|/       |/    \|      \|/       ◹◺
◹◺        \\|//   \\|///  \\\|//\\\|/// \|///  \\\|//  \\|//  \\\|//      ◹◺
◹◺    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   ◹◺
◹◺                                                                        ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Bouquet is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Bouquet",
        "BOKAY",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
