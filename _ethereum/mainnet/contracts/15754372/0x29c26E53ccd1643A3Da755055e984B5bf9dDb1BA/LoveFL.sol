
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IloveFL
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    I       //
//    Love    //
//    FL      //
//            //
//            //
////////////////


contract LoveFL is ERC721Creator {
    constructor() ERC721Creator("IloveFL", "LoveFL") {}
}
