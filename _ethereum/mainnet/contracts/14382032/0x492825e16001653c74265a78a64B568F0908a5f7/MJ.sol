
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tangled
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//           o           //
//        o^/|\^o        //
//     o_^|\/*\/|^_o     //
//    o\  ! \ / !  /o    //
//     \\\\\\|//////     //
//      !    MJ   !      //
//      `"""""""""`      //
//                       //
//                       //
///////////////////////////


contract MJ is ERC721Creator {
    constructor() ERC721Creator("Tangled", "MJ") {}
}
