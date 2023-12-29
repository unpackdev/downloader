// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LokoAI
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////
//              //
//              //
//    LoKoAI    //
//              //
//              //
//////////////////


contract LoKo is ERC721Creator {
    constructor() ERC721Creator("LokoAI", "LoKo") {}
}
