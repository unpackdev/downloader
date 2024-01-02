// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JANny721
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    JAftershock721JNY    //
//                         //
//                         //
/////////////////////////////


contract JNY721 is ERC721Creator {
    constructor() ERC721Creator("JANny721", "JNY721") {}
}
