// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Durango's Gallery
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract DG is ERC1155Creator {
    constructor() ERC1155Creator("Durango's Gallery", "DG") {}
}
