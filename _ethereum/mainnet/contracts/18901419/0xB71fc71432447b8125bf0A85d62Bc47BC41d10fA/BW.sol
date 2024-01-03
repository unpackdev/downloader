// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black waters
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    BW    //
//          //
//          //
//////////////


contract BW is ERC721Creator {
    constructor() ERC721Creator("Black waters", "BW") {}
}
