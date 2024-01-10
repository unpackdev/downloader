
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wrapped Ether
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////
//            //
//            //
//    WETH    //
//            //
//            //
////////////////


contract WETH is ERC1155Creator {
    constructor() ERC1155Creator() {}
}
