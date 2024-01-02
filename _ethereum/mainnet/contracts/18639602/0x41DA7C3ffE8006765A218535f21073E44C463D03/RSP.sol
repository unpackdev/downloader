// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Resplendence
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    .------..------..------.    //
//    |R.--. ||S.--. ||P.--. |    //
//    | :/\: || :(): || :/\: |    //
//    | :\/: || ()() || :\/: |    //
//    | '--'R|| '--'S|| '--'P|    //
//    `------'`------'`------'    //
//                                //
//                                //
////////////////////////////////////


contract RSP is ERC721Creator {
    constructor() ERC721Creator("Resplendence", "RSP") {}
}
