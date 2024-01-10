
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FCC Cakes
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    <>    //
//          //
//          //
//////////////


contract FCCC is ERC721Creator {
    constructor() ERC721Creator("FCC Cakes", "FCCC") {}
}
