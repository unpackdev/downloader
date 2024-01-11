
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: kara
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    kara    //
//            //
//            //
////////////////


contract KARA is ERC721Creator {
    constructor() ERC721Creator("kara", "KARA") {}
}
