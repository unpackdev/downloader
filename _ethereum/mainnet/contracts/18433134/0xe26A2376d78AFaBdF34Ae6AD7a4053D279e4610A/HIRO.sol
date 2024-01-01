// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: hiro
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////
//            //
//            //
//    HIRO    //
//            //
//            //
////////////////


contract HIRO is ERC721Creator {
    constructor() ERC721Creator("hiro", "HIRO") {}
}
