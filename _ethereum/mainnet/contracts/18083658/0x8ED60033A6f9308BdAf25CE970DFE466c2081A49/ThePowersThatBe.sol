// SPDX-License-Identifier: MIT

/// @title The Powers That Be by PAINTRE
/// @author transientlabs.xyz

/*////////////////////////////////////
//                                  //
//    _____ ____ _____ ____         //
//     |_   _|  _ \_   _| __ )      //
//       | | | |_) || | |  _ \      //
//       | | |  __/ | | | |_) |     //
//       |_| |_|    |_| |____/      //
//                                  //
//    T H E  P O W E R S  T H A T   //
//    B E  -  B Y  P A I N T R E    //
//                                  //
////////////////////////////////////*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract ThePowersThatBe is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "The Powers That Be",
        "TPTB",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
