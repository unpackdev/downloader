// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CharlieGnft
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    Ribbit    //
//              //
//              //
//////////////////


contract CGNFT is ERC721Creator {
    constructor() ERC721Creator("CharlieGnft", "CGNFT") {}
}
