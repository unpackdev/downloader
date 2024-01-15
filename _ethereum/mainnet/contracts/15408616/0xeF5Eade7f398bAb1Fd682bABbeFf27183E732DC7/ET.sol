
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: etest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    ¿?    //
//          //
//          //
//////////////


contract ET is ERC721Creator {
    constructor() ERC721Creator("etest", "ET") {}
}
