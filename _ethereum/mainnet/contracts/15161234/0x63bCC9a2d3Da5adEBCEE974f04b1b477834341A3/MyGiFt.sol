
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Gift
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    (((((((((((((((oooooooo))))))))))))))))    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract MyGiFt is ERC721Creator {
    constructor() ERC721Creator("My Gift", "MyGiFt") {}
}
