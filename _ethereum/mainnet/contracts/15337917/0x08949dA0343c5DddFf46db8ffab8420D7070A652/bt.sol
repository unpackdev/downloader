
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BY test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    by    //
//          //
//          //
//////////////


contract bt is ERC721Creator {
    constructor() ERC721Creator("BY test", "bt") {}
}
