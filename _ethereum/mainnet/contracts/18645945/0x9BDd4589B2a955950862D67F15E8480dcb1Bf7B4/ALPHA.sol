// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlphaFox
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    AlphaFox    //
//                //
//                //
////////////////////


contract ALPHA is ERC721Creator {
    constructor() ERC721Creator("AlphaFox", "ALPHA") {}
}
