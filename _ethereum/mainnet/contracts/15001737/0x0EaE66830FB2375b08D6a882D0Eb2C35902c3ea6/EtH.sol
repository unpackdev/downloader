
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Birthday boy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    101001    //
//              //
//              //
//////////////////


contract EtH is ERC721Creator {
    constructor() ERC721Creator("Birthday boy", "EtH") {}
}
