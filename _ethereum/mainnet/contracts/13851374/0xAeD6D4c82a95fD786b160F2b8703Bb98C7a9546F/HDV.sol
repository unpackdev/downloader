
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hodlov
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Children of men    //
//                       //
//                       //
///////////////////////////


contract HDV is ERC721Creator {
    constructor() ERC721Creator("Hodlov", "HDV") {}
}
