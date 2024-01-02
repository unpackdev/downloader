// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test12-2-721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    test12-2-721    //
//                    //
//                    //
////////////////////////


contract t122 is ERC721Creator {
    constructor() ERC721Creator("test12-2-721", "t122") {}
}
