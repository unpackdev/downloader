
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BitLady
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//       .----.        //
//       |C>_ |        //
//     __|____|__      //
//    |  ______--|     //
//    `-/.::::.\-'a    //
//     `--------'      //
//                     //
//                     //
/////////////////////////


contract BLDY is ERC721Creator {
    constructor() ERC721Creator("BitLady", "BLDY") {}
}
