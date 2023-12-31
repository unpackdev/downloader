// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: h3xum
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract h3xum is ERC1155Creator {
    constructor() ERC1155Creator("h3xum", "h3xum") {}
}
