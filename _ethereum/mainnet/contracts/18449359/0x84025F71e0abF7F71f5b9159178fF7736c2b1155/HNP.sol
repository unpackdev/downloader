// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Halloween Night Party
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//    .------..------..------.    //
//    |H.--. ||N.--. ||P.--. |    //
//    | :/\: || :(): || :/\: |    //
//    | (__) || ()() || (__) |    //
//    | '--'H|| '--'N|| '--'P|    //
//    `------'`------'`------'    //
//                                //
//                                //
//                                //
////////////////////////////////////


contract HNP is ERC721Creator {
    constructor() ERC721Creator("Halloween Night Party", "HNP") {}
}
