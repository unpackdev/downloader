
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mico Vicente
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    A simple line              //
//    painted with the brush     //
//    can lead to freedom        //
//    and happiness              //
//                -Joan Miro     //
//                               //
//                               //
//                               //
///////////////////////////////////


contract MICO is ERC721Creator {
    constructor() ERC721Creator("Mico Vicente", "MICO") {}
}
