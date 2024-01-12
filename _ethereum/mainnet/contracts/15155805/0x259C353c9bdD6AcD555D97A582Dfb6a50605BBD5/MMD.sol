
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MyMind
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//        ()_()      //
//       *(o_o)*     //
//        O( )O      //
//       MyMind🖤    //
//                   //
//                   //
///////////////////////


contract MMD is ERC721Creator {
    constructor() ERC721Creator("MyMind", "MMD") {}
}
