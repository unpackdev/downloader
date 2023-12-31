// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yo1155
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    yo    //
//          //
//          //
//////////////


contract YO is ERC1155Creator {
    constructor() ERC1155Creator("Yo1155", "YO") {}
}
