
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Keith Allen Phillips - Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    .------..------..------.    //
//    |K.--. ||A.--. ||P.--. |    //
//    | :/\: || (\/) || :/\: |    //
//    | :\/: || :\/: || (__) |    //
//    | '--'K|| '--'A|| '--'P|    //
//    `------'`------'`------'    //
//                                //
//                                //
//                                //
////////////////////////////////////


contract KAPED is ERC721Creator {
    constructor() ERC721Creator("Keith Allen Phillips - Editions", "KAPED") {}
}
