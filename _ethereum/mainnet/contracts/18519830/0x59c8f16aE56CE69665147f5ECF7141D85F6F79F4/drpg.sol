// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Drop Page
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    --    //
//          //
//          //
//////////////


contract drpg is ERC721Creator {
    constructor() ERC721Creator("Drop Page", "drpg") {}
}
