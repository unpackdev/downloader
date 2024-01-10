
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RVP Non-Fungible Token
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Potest solum unum    //
//                         //
//                         //
/////////////////////////////


contract RVP is ERC721Creator {
    constructor() ERC721Creator("RVP Non-Fungible Token", "RVP") {}
}
