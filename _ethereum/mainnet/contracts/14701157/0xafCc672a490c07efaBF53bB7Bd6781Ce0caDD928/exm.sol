
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: example
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    ..    //
//          //
//          //
//////////////


contract exm is ERC721Creator {
    constructor() ERC721Creator("example", "exm") {}
}
