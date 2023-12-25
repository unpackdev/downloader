
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Works by Emanuele Pasin
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Works by Emanuele Pasin    //
//                               //
//                               //
///////////////////////////////////


contract WEPS is ERC721Creator {
    constructor() ERC721Creator("Works by Emanuele Pasin", "WEPS") {}
}
