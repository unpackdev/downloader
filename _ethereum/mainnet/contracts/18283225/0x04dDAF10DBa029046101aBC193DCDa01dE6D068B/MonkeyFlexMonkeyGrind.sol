// SPDX-License-Identifier: MIT

/// @title Monkey flex, monkey grind
/// @author transientlabs.xyz

/*////////////////////////////////////////////////////////
//                                                      //
//    _    __  __ ______ __  __  _____    _             //
//      /\| |/\|  \/  |  ____|  \/  |/ ____|/\| |/\     //
//      \ ` ' /| \  / | |__  | \  / | |  __ \ ` ' /     //
//     |_     _| |\/| |  __| | |\/| | | |_ |_     _|    //
//      / , . \| |  | | |    | |  | | |__| |/ , . \     //
//      \/|_|\/|_|  |_|_|    |_|  |_|\_____|\/|_|\/     //
//                                                      //
//     *** MONKEY FLEX, MONKEY GRIND - BY PAINTRE ***   //
//                                                      //
////////////////////////////////////////////////////////*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract MonkeyFlexMonkeyGrind is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Monkey flex, monkey grind",
        "MFMG",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
