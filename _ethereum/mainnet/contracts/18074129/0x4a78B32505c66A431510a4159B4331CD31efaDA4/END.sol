// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENDLESS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    ♾️    //
//          //
//          //
//////////////


contract END is ERC721Creator {
    constructor() ERC721Creator("ENDLESS", "END") {}
}
