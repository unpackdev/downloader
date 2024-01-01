// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Buy Punk
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//      _          _              //
//     /_)/ //_/  /_// //|//_/    //
//    /_)/_/ /   /  /_// |/`\     //
//                                //
//                                //
//                                //
////////////////////////////////////


contract BUY is ERC721Creator {
    constructor() ERC721Creator("Buy Punk", "BUY") {}
}
