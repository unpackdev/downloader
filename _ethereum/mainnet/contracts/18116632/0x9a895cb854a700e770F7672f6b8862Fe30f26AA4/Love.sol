// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Compute Love Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract Love is ERC1155Creator {
    constructor() ERC1155Creator("Compute Love Editions", "Love") {}
}
