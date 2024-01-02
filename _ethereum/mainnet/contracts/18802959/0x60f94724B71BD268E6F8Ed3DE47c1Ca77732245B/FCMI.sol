// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FCMI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    🍊    //
//          //
//          //
//////////////


contract FCMI is ERC721Creator {
    constructor() ERC721Creator("FCMI", "FCMI") {}
}
