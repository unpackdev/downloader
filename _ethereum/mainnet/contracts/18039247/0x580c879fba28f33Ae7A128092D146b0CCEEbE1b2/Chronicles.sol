// SPDX-License-Identifier: MIT

/// @title Chronicles by Manu Williams
/// @author transientlabs.xyz

/*////////////////////////////
//                          //
//    ...                   //
//       xH88"`~ .x8X       //
//     :8888   .f"8888Hf    //
//    :8888>  X8L  ^""`     //
//    X8888  X888h          //
//    88888  !88888.        //
//    88888   %88888        //
//    88888 '> `8888>       //
//    `8888L %  ?888   !    //
//     `8888  `-*""   /     //
//       "888.      :"      //
//         `""***~"`        //
//                          //
////////////////////////////*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract Chronicles is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Chronicles",
        "CHRON",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
