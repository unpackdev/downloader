
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gifts
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    WRL has Presents    //
//                        //
//                        //
////////////////////////////


contract gift is ERC721Creator {
    constructor() ERC721Creator("Gifts", "gift") {}
}
