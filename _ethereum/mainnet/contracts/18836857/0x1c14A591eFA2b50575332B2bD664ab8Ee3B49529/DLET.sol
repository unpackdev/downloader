// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DL ETH Test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    DLET    //
//            //
//            //
////////////////


contract DLET is ERC721Creator {
    constructor() ERC721Creator("DL ETH Test", "DLET") {}
}
