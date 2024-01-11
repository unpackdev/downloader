
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Banana Challenge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Banana Challenge    //
//                        //
//                        //
////////////////////////////


contract BANCH is ERC721Creator {
    constructor() ERC721Creator("Banana Challenge", "BANCH") {}
}
