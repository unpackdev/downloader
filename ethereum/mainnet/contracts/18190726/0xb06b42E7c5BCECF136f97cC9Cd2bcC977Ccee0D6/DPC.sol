// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Pepe Cards by Bee
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////
//              //
//              //
//    (b ••)    //
//              //
//              //
//////////////////


contract DPC is ERC1155Creator {
    constructor() ERC1155Creator("Dark Pepe Cards by Bee", "DPC") {}
}
