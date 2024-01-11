
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moonbirds
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//      , _ ,      //
//     ( o o )     //
//    /'` ' `'\    //
//    |'''''''|    //
//    |\\'''//|    //
//       """       //
//                 //
//                 //
/////////////////////


contract MOONBIRD is ERC721Creator {
    constructor() ERC721Creator("Moonbirds", "MOONBIRD") {}
}
