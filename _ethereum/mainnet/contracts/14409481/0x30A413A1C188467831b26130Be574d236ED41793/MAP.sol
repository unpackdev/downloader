
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meta Apes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    test    //
//            //
//            //
////////////////


contract MAP is ERC721Creator {
    constructor() ERC721Creator("Meta Apes", "MAP") {}
}
