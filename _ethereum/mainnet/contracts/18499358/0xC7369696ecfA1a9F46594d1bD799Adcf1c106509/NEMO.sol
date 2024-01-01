// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NEMO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    NEMO    //
//            //
//            //
////////////////


contract NEMO is ERC721Creator {
    constructor() ERC721Creator("NEMO", "NEMO") {}
}
