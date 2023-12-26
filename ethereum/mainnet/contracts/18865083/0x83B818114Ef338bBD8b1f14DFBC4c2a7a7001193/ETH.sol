// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mazi AI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    MAZI    //
//            //
//            //
////////////////


contract ETH is ERC721Creator {
    constructor() ERC721Creator("mazi AI", "ETH") {}
}
